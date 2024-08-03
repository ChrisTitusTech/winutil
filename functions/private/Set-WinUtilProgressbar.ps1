function Set-WinUtilProgressbar{
    <#
    .SYNOPSIS
        This function is used to Update the Progress Bar displayed in the winutil GUI. 
        It will be automatically hidden if the user clicks something and no process is running 
    .PARAMETER Label
        The Text to be overlayed onto the Progress Bar
    .PARAMETER PERCENT
        The percentage of the Progress Bar that should be filled (0-100) 
    .PARAMETER Hide
        If provided, the Progress Bar and the label will be hidden
    #>
    param(
        [string]$Label,
        [ValidateRange(0,100)]
        [int]$Percent,
        $Hide
    )
    if ($hide){
        $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBarLabel.Visibility = "Collapsed"}) 
        $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBar.Visibility = "Collapsed"})     
    }
    else{
        $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBarLabel.Visibility = "Visible"}) 
        $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBar.Visibility = "Visible"})     
    }
    $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBarLabel.Content.Text = $label}) 
    $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBarLabel.Content.ToolTip = $label}) 
    $sync.form.Dispatcher.Invoke([action]{ $sync.ProgressBar.Value = $percent})
    
}