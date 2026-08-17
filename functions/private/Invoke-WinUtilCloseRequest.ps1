function Invoke-WinUtilCloseRequest {
    <#
        .SYNOPSIS
            Asks what to do about work that is still running when the window is closed

        .DESCRIPTION
            An install or a set of tweaks that is halfway through is not something to end without
            asking. Either it finishes without the window, reporting to the console until it is
            done and then exiting, or it is stopped and everything closes now.

        .PARAMETER RunningJob
            The name of the job in flight, so the question names what is at stake.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$RunningJob
    )

    # The question carries the meaning rather than a list naming the buttons: Windows labels
    # them in its own language, so "Yes" in the text does not match a button reading "Ja".
    $answer = Show-WinUtilMessage -Button "YesNoCancel" -Icon "Warning" -Title "$RunningJob is still running" -Message @"
$RunningJob has not finished yet.

Close the window and let it finish in the console?

WinUtil will exit on its own once it is done. If you do not, it will be
stopped and everything closes now. Cancel keeps WinUtil open.
"@

    switch ("$answer") {
        "Yes" {
            Write-WinUtilLog -Component "UI" -Message "Close requested: closing the window, $RunningJob continues in the console."
            $sync.FinishInConsole = $true
            $sync.ForceClose = $true

            # Once the window is gone there is no button left to resume with, so a run that is
            # holding would never reach its end
            $sync.JobPaused = $false

            Write-Host ""
            Write-Host "WinUtil's window is closed. $RunningJob is still running here, and this window will close when it finishes." -ForegroundColor Cyan
            Write-Host ""

            # Posted rather than closed from inside the handler that is already unwinding
            Request-WinUtilWindowClose
        }
        "No" {
            Write-WinUtilLog -Component "UI" -Message "Close requested: stopping $RunningJob."
            Write-WinUtilJobProgress -Status "Stopping $RunningJob" -State "Indeterminate"
            $sync.ForceClose = $true

            # Stopping can take a moment that would otherwise look like the window had frozen
            Request-WinUtilWindowClose -Before {
                Close-WinUtilRunspacePool
                $sync.ActiveJob = $null
            }
        }
        default {
            Write-WinUtilLog -Component "UI" -Message "Close cancelled, $RunningJob is still running."
        }
    }
}

function Request-WinUtilWindowClose {
    <#
        .SYNOPSIS
            Closes the window from outside the handler that is currently cancelling the close

        .PARAMETER Before
            Work to do on the interface thread first, before the window goes.
    #>
    param(
        [scriptblock]$Before
    )

    if (-not (Test-WinUtilUIAlive)) {
        return
    }

    $sync.PendingCloseWork = $Before
    $sync.Form.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{
        if ($sync.PendingCloseWork) {
            & $sync.PendingCloseWork
            $sync.PendingCloseWork = $null
        }
        $sync.Form.Close()
    }) | Out-Null
}

function Wait-WinUtilRemainingWork {
    <#
        .SYNOPSIS
            Waits for work that outlived the window, reporting to the console

        .DESCRIPTION
            Runs on the main thread once the interface has gone. The job itself is still on the
            worker pool and keeps logging, so there is nothing to do here but wait for it and
            keep the wait visible.

        .PARAMETER TimeoutMinutes
            An upper bound, so a worker that never returns cannot keep the process alive for good.
    #>
    param(
        [int]$TimeoutMinutes = 120
    )

    if (-not $sync.FinishInConsole -or -not $sync.ActiveJob) {
        return
    }

    $job = $sync.ActiveJob
    Write-WinUtilLog -Component "UI" -Message "Window closed, waiting for $job to finish."
    Write-Host "Waiting for $job to finish..." -ForegroundColor Cyan

    $clock = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sync.ActiveJob -and $clock.Elapsed.TotalMinutes -lt $TimeoutMinutes) {
        Start-Sleep -Milliseconds 250
    }

    # The job's last progress line is still open, so anything after it needs a fresh line
    Complete-WinUtilConsoleProgress

    if ($sync.ActiveJob) {
        Write-WinUtilLog -Level "WARN" -Component "UI" -Message "$job did not finish within $TimeoutMinutes minutes, exiting anyway."
        Write-Host "$job is taking longer than $TimeoutMinutes minutes. Exiting." -ForegroundColor Yellow
        return
    }

    Write-WinUtilLog -Component "UI" -Message "$job finished after the window closed, in $([int]$clock.Elapsed.TotalSeconds)s."
    Write-Host "$job finished. Closing." -ForegroundColor Green
}
