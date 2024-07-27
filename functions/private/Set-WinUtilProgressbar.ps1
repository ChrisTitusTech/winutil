
function Set-WinUtilProgressbar{
    param(
        [string]$label,
        [int]$percent,
        $hide
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