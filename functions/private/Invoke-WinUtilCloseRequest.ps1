function Invoke-WinUtilCloseRequest {
    <#
        .SYNOPSIS
            Asks what to do about work that is still running when the window is closed

        .DESCRIPTION
            An install or a set of tweaks that is halfway through is not something to end without
            asking. The choice is to let it finish and close afterwards, or to stop it and close
            now. Either way the pool is shut down in order rather than pulled away from work that
            is still using it.

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

Wait for it to finish before closing WinUtil?

If you do not wait, it will be stopped. Cancel keeps WinUtil open.
"@

    switch ("$answer") {
        "Yes" {
            $sync.CloseWhenIdle = $true
            Write-WinUtilLog -Component "UI" -Message "Close requested: waiting for $RunningJob to finish first."
            Write-WinUtilJobProgress -Status "$RunningJob is finishing, WinUtil will close when it is done"

            # It may have finished between the question and the answer, in which case nothing is
            # left to raise the completion that would close the window
            if (-not $sync.ActiveJob) {
                Complete-WinUtilPendingClose
            }
        }
        "No" {
            Write-WinUtilLog -Component "UI" -Message "Close requested: stopping $RunningJob."
            Write-WinUtilJobProgress -Status "Stopping $RunningJob" -State "Indeterminate"
            $sync.ForceClose = $true

            # Posted rather than run here: the dialog is still unwinding, and stopping can take a
            # moment that would otherwise look like the window had frozen
            $sync.Form.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{
                Close-WinUtilRunspacePool
                $sync.ActiveJob = $null
                $sync.Form.Close()
            }) | Out-Null
        }
        default {
            $sync.CloseWhenIdle = $false
            Write-WinUtilLog -Component "UI" -Message "Close cancelled, $RunningJob is still running."
        }
    }
}

function Complete-WinUtilPendingClose {
    <#
        .SYNOPSIS
            Closes the window once the job it was waiting on has finished

        .DESCRIPTION
            Called from a worker as its job ends, so the close itself is posted to the thread that
            owns the window.
    #>

    if (-not $sync.CloseWhenIdle) {
        return
    }

    $sync.CloseWhenIdle = $false
    $sync.ForceClose = $true

    if ($null -eq $sync.Form -or $null -eq $sync.Form.Dispatcher -or $sync.Form.Dispatcher.HasShutdownStarted) {
        return
    }

    $sync.Form.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{
        Write-WinUtilLog -Component "UI" -Message "The job that was running has finished, closing now."
        $sync.Form.Close()
    }) | Out-Null
}
