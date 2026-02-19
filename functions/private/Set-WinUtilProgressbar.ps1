function Set-WinUtilProgressbar{
    <#
    .SYNOPSIS
        This function is used to Update the Progress Bar displayed in the winutil GUI.
        It will be automatically hidden if the user clicks something and no process is running
    .PARAMETER Label
        The Text to be overlaid onto the Progress Bar
    .PARAMETER PERCENT
        The percentage of the Progress Bar that should be filled (0-100)
    #>
    param(
        [string]$Label,
        [ValidateRange(0,100)]
        [int]$Percent
    )

    if($PARAM_NOUI) {
        return;
    }

    Invoke-WPFUIThread -ScriptBlock {$sync.progressBarTextBlock.Text = $label}
    Invoke-WPFUIThread -ScriptBlock {$sync.progressBarTextBlock.ToolTip = $label}
    if ($percent -lt 5 ) {
        $percent = 5 # Ensure the progress bar is not empty, as it looks weird
    }
    Invoke-WPFUIThread -ScriptBlock { $sync.ProgressBar.Value = $percent}

}
