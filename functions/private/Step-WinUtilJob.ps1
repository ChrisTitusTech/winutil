function Step-WinUtilJob {
    <#
        .SYNOPSIS
            Advances a job to its next reportable point, honouring a pause or stop on the way

        .DESCRIPTION
            Every loop calls this, so it is the one point a run reliably passes between steps and
            therefore the only place it can be held or ended without cutting into a command in
            flight. It blocks while the run is paused and throws OperationCanceledException once
            a stop is asked for, so calling it from a finally, or from a catch already reporting
            a failure, re-raises that stop. The job layer clears the flags before its own finish
            reporting for that reason.

            Drives the progress bar and taskbar item together and does nothing without a window,
            so job bodies need no UI checks. The update is posted rather than waited on: a job
            reporting per item would otherwise stall on the interface thread each time.

        .PARAMETER Status
            Text for the progress label

        .PARAMETER Percent
            Completion between 0 and 100

        .PARAMETER State
            Taskbar state. Normal while working, Error on failure, None when finished.

        .PARAMETER Overlay
            Taskbar overlay icon: logo, checkmark, warning or None

        .PARAMETER Hide
            Clears and hides the progress bar. Used when leaving a finished job behind rather
            than while one is running.
    #>
    param(
        [string]$Status,
        [int]$Percent = -1,
        [ValidateSet("Normal", "Error", "Paused", "Indeterminate", "None")]
        [string]$State,
        [string]$Overlay,
        [switch]$Hide
    )

    # With no window every update is thrown away, and a window closed over running work counts
    # as none: its dispatcher accepts posts and discards them. The console is what is left.
    if (-not (Test-WinUtilUIAlive)) {
        if (-not $Hide) {
            Write-WinUtilConsoleProgress -Status $Status -Percent $Percent
        }
        return
    }

    Invoke-WPFUIThread -Async -Parameters @{
        Status = $Status
        Percent = [Math]::Min([Math]::Max($Percent, -1), 100)
        State = $State
        Overlay = $Overlay
        HideBar = [bool]$Hide
        HasStatus = $PSBoundParameters.ContainsKey('Status')
        HasState = $PSBoundParameters.ContainsKey('State')
        HasOverlay = $PSBoundParameters.ContainsKey('Overlay')
    } -ScriptBlock {
        param($Status, $Percent, $State, $Overlay, $HideBar, $HasStatus, $HasState, $HasOverlay)

        if ($HideBar) {
            $sync.WPFTweaksProgressBar.Visibility = [Windows.Visibility]::Collapsed
            $sync.WPFTweaksProgressLabel.Text = ""
            $sync.WPFTweaksProgressLabel.ToolTip = $null
            $sync.WPFTweaksProgressValue.Value = 0
            return
        }

        $hasPercent = $Percent -ge 0

        if ($HasStatus -or $hasPercent) {
            $sync.WPFTweaksProgressBar.Visibility = [Windows.Visibility]::Visible
        }
        if ($HasStatus) {
            $sync.WPFTweaksProgressLabel.Text = $Status
            $sync.WPFTweaksProgressLabel.ToolTip = $Status
        }
        if ($hasPercent) {
            $sync.WPFTweaksProgressValue.Value = $Percent
            $sync.Form.TaskbarItemInfo.ProgressValue = $Percent / 100
        }
        if ($HasState) {
            # Pulse in place at whatever progress has been reached. IsIndeterminate would make
            # WPF discard Value and fill the whole bar, which reads as finished.
            $sync.WPFTweaksProgressValue.Tag = if ($State -eq "Indeterminate") { "Pulse" } else { $null }

            # By resource reference rather than a fixed brush, so switching theme repaints it
            $barColor = switch ($State) {
                "Error"  { "ProgressBarErrorColor" }
                "Paused" { "ProgressBarWarningColor" }
                default  { "ProgressBarForegroundColor" }
            }
            $sync.WPFTweaksProgressValue.SetResourceReference([Windows.Controls.Control]::ForegroundProperty, $barColor)

            Set-WinUtilTaskbaritem -state $State
        }
        if ($HasOverlay) {
            Set-WinUtilTaskbaritem -overlay $Overlay
        }
    }
}
