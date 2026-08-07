function Invoke-WPFUIThread ($ScriptBlock) {
    if ($null -eq $sync.form -or $null -eq $sync.form.Dispatcher) {
        return
    }

    $sync.form.Dispatcher.Invoke([action]$ScriptBlock)
}
