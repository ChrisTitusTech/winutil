function Invoke-WPFUIThread ($ScriptBlock) {
    $sync.form.Dispatcher.Invoke([action]$ScriptBlock)
}
