function Invoke-WPFUIThread {
    <#

    .SYNOPSIS
        Creates and runs a task on Winutil's WPF Forms thread.

    .PARAMETER ScriptBlock
        The scriptblock to invoke in the thread
    #>

    [CmdletBinding()]
    Param (
        $ScriptBlock
    )

    $sync.form.Dispatcher.Invoke([action]$ScriptBlock)
}
