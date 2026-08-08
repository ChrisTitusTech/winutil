function Write-WinUtilJobProgress {
    <#
        .SYNOPSIS
            Reports progress from inside a WinUtil job

        .DESCRIPTION
            The only progress call a job body needs. It drives the progress bar and the taskbar
            item together, and does nothing when there is no window, so job bodies do not need
            their own "is there a UI" checks.

            The update is posted rather than waited on: a job reporting progress per item would
            otherwise stall on the interface thread once per item.

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

    # With no window there is nothing to post to, and every update would be thrown away. A
    # headless run is the one that most needs to say what it is doing. A window that has been
    # closed over running work counts as no window: its dispatcher accepts posts and discards
    # them, so the console is the only place left to report.
    if ($null -eq $sync.Form -or $null -eq $sync.Form.Dispatcher -or $sync.Form.Dispatcher.HasShutdownStarted) {
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
            Set-WinUtilTaskbaritem -state $State
        }
        if ($HasOverlay) {
            Set-WinUtilTaskbaritem -overlay $Overlay
        }
    }
}
