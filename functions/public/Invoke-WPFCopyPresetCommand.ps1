function Invoke-WPFCopyPresetCommand {
    <#
        .SYNOPSIS
            Copies the PowerShell command for a specific preset to the clipboard
        .PARAMETER Preset
            The preset name
    #>
    param($Preset)

    $command = "iex ""`& { `$(irm https://christitus.com/win) } -Preset $Preset"""
    $command | Set-Clipboard

    [System.Windows.MessageBox]::Show("PowerShell command for $Preset preset copied to clipboard!`n`n$command", "Winutil", "OK", "Information")
}
