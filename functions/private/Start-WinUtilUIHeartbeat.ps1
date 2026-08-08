function Start-WinUtilUIHeartbeat {
    <#
        .SYNOPSIS
            Records how long the interface thread stops answering, and what it was doing

        .DESCRIPTION
            A timer at input priority cannot tick while the thread is busy with something else,
            so the gap between two ticks is how long a click arriving at that moment would have
            waited. That is the number a user feels, and it is not visible from outside the
            process: an automation probe cannot tell a blocked thread from a slow reply.

            Off unless WINUTIL_TRACE_UI is 1. It is a diagnostic for working on startup, not
            something a normal run should pay for.
    #>

    if ($env:WINUTIL_TRACE_UI -ne "1") {
        return
    }

    $sync.UIStalls = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
    $sync.UIHeartbeatLast = [datetime]::Now
    $sync.UIHeartbeatStart = [datetime]::Now

    $timer = New-Object System.Windows.Threading.DispatcherTimer([System.Windows.Threading.DispatcherPriority]::Input)
    $timer.Interval = [timespan]::FromMilliseconds(15)
    $timer.Add_Tick({
        $now = [datetime]::Now
        $gap = ($now - $sync.UIHeartbeatLast).TotalMilliseconds
        $sync.UIHeartbeatLast = $now

        # Every gap, not just the long ones. A thread kept busy by a stream of short pieces of
        # work never shows a single long stall, but everything the user does still waits behind
        # whatever piece is running, and that is what reads as lag.
        $null = $sync.UIStalls.Add([pscustomobject]@{
            AtMs = [int]($now - $sync.UIHeartbeatStart).TotalMilliseconds
            Milliseconds = [int]$gap
        })
    })
    $timer.Start()
    $sync.UIHeartbeatTimer = $timer

    Write-WinUtilLog -Component "UI" -Message "Interface stall tracing is on."

    # Report at a fixed time from here. Scheduling this behind an idle callback made the report
    # depend on the thread going idle, which is exactly what is in question.
    $reportTimer = New-Object System.Windows.Threading.DispatcherTimer([System.Windows.Threading.DispatcherPriority]::Normal)
    $reportTimer.Interval = [timespan]::FromSeconds(20)
    $reportTimer.Add_Tick({
        $this.Stop()
        Stop-WinUtilUIHeartbeat
    })
    $reportTimer.Start()
    $sync.UIHeartbeatReportTimer = $reportTimer
}

function Stop-WinUtilUIHeartbeat {
    <#
        .SYNOPSIS
            Stops stall tracing and writes what it saw to the log
    #>

    if ($sync.UIHeartbeatTimer) {
        $sync.UIHeartbeatTimer.Stop()
        $sync.UIHeartbeatTimer = $null
    }

    $samples = @($sync.UIStalls)
    if ($samples.Count -eq 0) {
        Write-WinUtilLog -Component "UI" -Message "stall report: no samples were taken."
        return
    }

    function Get-Percentile {
        param($Sorted, [double]$Fraction)
        $index = [Math]::Min($Sorted.Count - 1, [Math]::Max(0, [int][Math]::Ceiling($Sorted.Count * $Fraction) - 1))
        return $Sorted[$index]
    }

    # The window the user actually complains about is while the app list is filling in
    foreach ($window in @(
            @{ Name = "first 3s"; From = 0; To = 3000 },
            @{ Name = "3s to 10s"; From = 3000; To = 10000 },
            @{ Name = "whole run"; From = 0; To = [int]::MaxValue })) {

        $inWindow = @($samples | Where-Object { $_.AtMs -ge $window.From -and $_.AtMs -lt $window.To })
        if ($inWindow.Count -eq 0) { continue }

        $values = @($inWindow | ForEach-Object { $_.Milliseconds } | Sort-Object)
        $overFifty = @($values | Where-Object { $_ -gt 50 }).Count

        Write-WinUtilLog -Component "UI" -Message ("stall report {0}: {1} samples, median {2} ms, p90 {3} ms, p99 {4} ms, worst {5} ms, {6} over 50 ms" -f `
            $window.Name, $inWindow.Count, (Get-Percentile -Sorted $values -Fraction 0.5), (Get-Percentile -Sorted $values -Fraction 0.9),
            (Get-Percentile -Sorted $values -Fraction 0.99), $values[-1], $overFifty)
    }
}
