function Set-WinUtilTweaksProgressIndicator {
    <#
    .SYNOPSIS
        Shows, updates, or hides the window-level progress indicator used by long-running
        workflows such as Tweaks, Undo, and AppX management. It lives outside the TabControl,
        so unlike the Install tab's progress bar it stays visible no matter which tab is active.
    .PARAMETER Visible
        Whether the indicator should be shown or hidden.
    .PARAMETER Label
        The text to display above the progress bar.
    .PARAMETER Percent
        The percentage of the progress bar that should be filled (0-100).
    #>
    param(
        [bool]$Visible,
        [string]$Label,
        [ValidateRange(0,100)]
        [int]$Percent
    )

    $indicatorVisible = if ($Visible) { [Windows.Visibility]::Visible } else { [Windows.Visibility]::Collapsed }
    $indicatorLabel = $Label
    $hasLabel = $PSBoundParameters.ContainsKey('Label')
    $hasPercent = $PSBoundParameters.ContainsKey('Percent')

    Invoke-WPFUIThread -ScriptBlock {
        $sync.WPFTweaksProgressBar.Visibility = $indicatorVisible
        if ($hasLabel) {
            $sync.WPFTweaksProgressLabel.Text = $indicatorLabel
        }
        if ($hasPercent) {
            $sync.WPFTweaksProgressValue.Value = $Percent
        }
    }
}
