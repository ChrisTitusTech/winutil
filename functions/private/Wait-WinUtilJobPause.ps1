function Wait-WinUtilJobPause {
    <#
        .SYNOPSIS
            Holds a job at a safe point while it is paused

        .DESCRIPTION
            A running command cannot be suspended halfway: an installer that has been started has
            to be allowed to return. What can be paused is the run itself, between one step and
            the next, which is where this is called from.

            Only a job's own worker is ever held. Whoever sets the pause reports it through the
            same progress call, and a caller that held there would be waiting on itself: on the
            interface thread that means freezing the button that would resume it, and with no
            window at all it means never returning.
    #>

    if (-not $sync.JobPaused) {
        return
    }

    # Set by the job layer inside the worker, so it is true on the thread doing the work and
    # nowhere else. Runspace scoped, so a pool runspace carries it between jobs, which is right.
    if (-not $global:WinUtilIsJobWorker) {
        return
    }

    Write-WinUtilLog -Component $(if ($sync.ActiveJob) { $sync.ActiveJob } else { "UI" }) -Message "Paused, waiting to be resumed."
    $clock = [System.Diagnostics.Stopwatch]::StartNew()

    while ($sync.JobPaused -and -not $sync.ShuttingDown) {
        Start-Sleep -Milliseconds 200
    }

    Write-WinUtilLog -Component $(if ($sync.ActiveJob) { $sync.ActiveJob } else { "UI" }) -Message "Resumed after $([int]$clock.Elapsed.TotalSeconds)s paused."
}

function Set-WinUtilJobPaused {
    <#
        .SYNOPSIS
            Pauses or resumes the running job and updates the button that did it

        .PARAMETER Paused
            Whether the run should hold at its next step.
    #>
    param(
        [Parameter(Mandatory)]
        [bool]$Paused
    )

    $sync.JobPaused = $Paused

    if ($sync.WPFPauseJobButton) {
        # Play glyph to resume, pause glyph to pause
        $sync.WPFPauseJobButton.Content = if ($Paused) { [string]([char]0xE768) } else { [string]([char]0xE769) }
        $sync.WPFPauseJobButton.ToolTip = if ($Paused) { "Resume" } else { "Pause after the current step" }
    }

    if ($Paused) {
        Write-WinUtilLog -Component "UI" -Message "Pause requested, the run will hold after the current step."
        Step-WinUtilJob -Status "Pausing after the current step" -State "Paused"
    } else {
        Write-WinUtilLog -Component "UI" -Message "Resume requested."
        Step-WinUtilJob -State "Normal"
    }
}
