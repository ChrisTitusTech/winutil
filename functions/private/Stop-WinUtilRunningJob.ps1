function Stop-WinUtilJobIfRequested {
    <#
        .SYNOPSIS
            Ends the run at a safe point when a stop has been asked for

        .DESCRIPTION
            Called from the same place a pause is honoured, which is between one step and the
            next. Stopping there leaves the machine in a state the run itself chose, rather than
            halfway through whatever a command happened to be doing.

            Throws, because that is how a run is abandoned from inside arbitrary job code. The
            job layer recognises this exception and reports the run as stopped rather than failed.
    #>

    if (-not $sync.StopRequested) {
        return
    }

    # Only the worker doing the work unwinds; whoever pressed the button must carry on
    if (-not $global:WinUtilIsJobWorker) {
        return
    }

    throw [System.OperationCanceledException]::new("WinUtil job stopped at the user's request.")
}

function Stop-WinUtilRunningJob {
    <#
        .SYNOPSIS
            Stops the running action, asking first

        .DESCRIPTION
            The run is asked to stop at its next step, which lets it unwind cleanly and report
            what it did. A step that never reaches another safe point, a single long install for
            instance, is cut off after a grace period so the button always does something.
    #>
    param(
        [int]$GraceSeconds = 20
    )

    $job = $sync.ActiveJob
    if (-not $job) {
        return
    }

    $answer = Show-WinUtilMessage -Button "YesNo" -Icon "Warning" -Title "Stop $job?" -Message @"
$job is still running.

Stop it? It will end after the step it is on, so anything already started
finishes first. Whatever has not been done yet will be skipped.
"@

    if ("$answer" -ne "Yes") {
        Write-WinUtilLog -Component "UI" -Message "Stop cancelled, $job is still running."
        return
    }

    Write-WinUtilLog -Component "UI" -Message "Stop requested for $job."
    $sync.StopRequested = $true

    # A run that is holding would never reach the point where it notices the stop
    $sync.JobPaused = $false

    Step-WinUtilJob -Status "Stopping $job" -State "Indeterminate"
    if ($sync.WPFStopJobButton) { $sync.WPFStopJobButton.IsEnabled = $false }
    if ($sync.WPFPauseJobButton) { $sync.WPFPauseJobButton.IsEnabled = $false }

    Start-WinUtilJobStopWatchdog -Job $job -GraceSeconds $GraceSeconds
}

function Start-WinUtilJobStopWatchdog {
    <#
        .SYNOPSIS
            Cuts a run off if it does not stop on its own

        .DESCRIPTION
            Asking is not enough on its own: a job inside one long command reaches no safe point
            until that command returns. After the grace period the worker is stopped outright.

            Every tick runs on the interface thread, so nothing here waits. The stop is issued
            once and later ticks watch for it to take effect, rather than sleeping on the thread
            that has to keep the window responsive.

        .PARAMETER Job
            The job that was asked to stop, for the log.

        .PARAMETER GraceSeconds
            How long to let it end by itself first.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Job,

        [int]$GraceSeconds = 20
    )

    if (-not (Test-WinUtilUIAlive)) {
        return
    }

    $timer = New-Object System.Windows.Threading.DispatcherTimer([System.Windows.Threading.DispatcherPriority]::Background)
    $timer.Interval = [timespan]::FromMilliseconds(500)
    # The run being cut off is identified by its token, so a watchdog that fires late cannot
    # release a slot that the next job has already claimed
    $timer.Tag = @{ Job = $Job; Token = $sync.ActiveJobToken; Deadline = (Get-Date).AddSeconds($GraceSeconds); CutOff = $null }
    $timer.Add_Tick({
        param($eventSender)
        $ticked = [System.Windows.Threading.DispatcherTimer]$eventSender
        $state = $ticked.Tag

        # Gone, or replaced by a later run that this watchdog has no business touching
        if (-not $sync.ActiveJob -or $sync.ActiveJobToken -ne $state.Token) {
            $ticked.Stop()
            Write-WinUtilLog -Component "UI" -Message "$($state.Job) stopped."
            $sync.StopRequested = $false
            return
        }

        # Every branch below runs on the interface thread, so none of them may wait. The stop is
        # issued once and its progress is watched on later ticks instead.
        if (-not $state.CutOff) {
            if ((Get-Date) -lt $state.Deadline) {
                return
            }

            Write-WinUtilLog -Level "WARN" -Component "UI" -Message "$($state.Job) did not stop on its own, cutting it off."
            Stop-WinUtilActiveWork -NoWait | Out-Null
            $state.CutOff = (Get-Date)
            return
        }

        if ((Test-WinUtilActiveWorkRunning) -and ((Get-Date) - $state.CutOff).TotalSeconds -lt 10) {
            return
        }

        $ticked.Stop()
        $sync.StopRequested = $false
        if (Clear-WinUtilActiveJob -Token $state.Token) {
            Step-WinUtilJob -Status "$($state.Job) stopped" -Percent 100 -State "Paused" -Overlay "warning"
            if ($null -ne $sync.ItemsControl) { $sync.ItemsControl.IsEnabled = $true }
        }
    })
    $timer.Start()
    $sync.StopWatchdogTimer = $timer
}
