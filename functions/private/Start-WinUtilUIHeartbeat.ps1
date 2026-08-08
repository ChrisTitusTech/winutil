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

        # 60ms is roughly where a delay stops reading as instant
        if ($gap -gt 60) {
            $null = $sync.UIStalls.Add([pscustomobject]@{
                AtMs = [int]($now - $sync.UIHeartbeatStart).TotalMilliseconds
                Milliseconds = [int]$gap
            })
        }
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

    $stalls = @($sync.UIStalls)
    if ($stalls.Count -eq 0) {
        Write-WinUtilLog -Component "UI" -Message "stall report: the interface never stopped answering for more than 60 ms."
        return
    }

    $total = ($stalls | Measure-Object -Property Milliseconds -Sum).Sum
    $worst = ($stalls | Measure-Object -Property Milliseconds -Maximum).Maximum
    Write-WinUtilLog -Component "UI" -Message "stall report: $($stalls.Count) stall(s) over 60 ms, $total ms unresponsive in total, worst $worst ms."

    foreach ($stall in ($stalls | Sort-Object Milliseconds -Descending | Select-Object -First 15)) {
        Write-WinUtilLog -Component "UI" -Detail -Message "stall of $($stall.Milliseconds) ms at $($stall.AtMs) ms after the window appeared"
    }
}
