function Show-WinUtilMessage {
    <#
    .SYNOPSIS
        Shows a WinUtil message box and returns the selected result.

    .DESCRIPTION
        Message boxes need the interface thread, so this marshals onto it and can therefore be
        called from a job body as well as from an event handler. Every prompt is also written to
        the session log so the log shows what the user was asked and not just what happened next.
    #>
    param (
        [string]$Message,
        [string]$Title = "Winutil",
        $Button = "OK",
        $Icon = "Information"
    )

    Write-WinUtilLog -Component "Dialog" -Message "$Title : $($Message -replace '\r?\n', ' ')"

    if ($null -eq $sync.Form -or $null -eq $sync.Form.Dispatcher) {
        return [System.Windows.MessageBox]::Show($Message, $Title, $Button, $Icon)
    }

    return Invoke-WPFUIThread -Parameters @{
        Message = $Message
        Title = $Title
        Button = $Button
        Icon = $Icon
    } -ScriptBlock {
        param($Message, $Title, $Button, $Icon)

        [System.Windows.MessageBox]::Show($Message, $Title, $Button, $Icon)
    }
}
