function Write-WinUtilJobProgress {
    <#
        .SYNOPSIS
            Reports progress from inside a WinUtil job

        .DESCRIPTION
            The only progress call a job body needs. It drives the progress bar and the taskbar
            item together, and does nothing when there is no window, so job bodies do not need
            their own "is there a UI" checks.

            UI updates are posted rather than waited on. A job that reports progress per item
            would otherwise block on the dispatcher once per item.

        .PARAMETER Status
            Text for the progress label

        .PARAMETER Percent
            Completion between 0 and 100

        .PARAMETER State
            Taskbar state. Normal while working, Error on failure, None when finished.

        .PARAMETER Overlay
            Taskbar overlay icon: logo, checkmark, warning or None
    #>
    param(
        [string]$Status,
        [ValidateRange(0, 100)]
        [int]$Percent = -1,
        [ValidateSet("Normal", "Error", "Paused", "Indeterminate", "None")]
        [string]$State,
        [string]$Overlay
    )

    if ($null -eq $sync.Form -or $null -eq $sync.Form.Dispatcher) {
        return
    }

    $hasStatus = $PSBoundParameters.ContainsKey('Status')
    $hasPercent = $Percent -ge 0
    $hasState = $PSBoundParameters.ContainsKey('State')
    $hasOverlay = $PSBoundParameters.ContainsKey('Overlay')

    $update = {
        if ($hasStatus -or $hasPercent) {
            $sync.WPFTweaksProgressBar.Visibility = [Windows.Visibility]::Visible
        }
        if ($hasStatus) {
            $sync.WPFTweaksProgressLabel.Text = $Status
            $sync.WPFTweaksProgressLabel.ToolTip = $Status
        }
        if ($hasPercent) {
            $sync.WPFTweaksProgressValue.Value = $Percent
            $sync.Form.TaskbarItemInfo.ProgressValue = $Percent / 100
        }
        if ($hasState) {
            Set-WinUtilTaskbaritem -state $State
        }
        if ($hasOverlay) {
            Set-WinUtilTaskbaritem -overlay $Overlay
        }
    }

    $null = $sync.Form.Dispatcher.BeginInvoke([Windows.Threading.DispatcherPriority]::Background, [action]$update)
}
