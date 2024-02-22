
function Invoke-WPFShortcut {
    <#

    .SYNOPSIS
        Creates a shortcut and prompts for a save location

    .PARAMETER ShortcutToAdd
        The name of the shortcut to add

    .PARAMETER RunAsAdmin
        A boolean value to make 'Run as administrator' property on (true) or off (false), defaults to off

    #>
    param(
        $ShortcutToAdd,
        [bool]$RunAsAdmin = $false
    )

        $iconPath = $null
        Switch ($ShortcutToAdd) {
            "WinUtil" {
                $SourceExe = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
                $IRM = 'irm https://christitus.com/win | iex'
                $Powershell = '-ExecutionPolicy Bypass -Command "Start-Process powershell.exe -verb runas -ArgumentList'
                $ArgumentsToSourceExe = "$powershell '$IRM'"
                $DestinationName = "WinUtil.lnk"

                if (Test-Path -Path "$env:TEMP\cttlogo.png") {
                    $iconPath = "$env:SystempRoot\cttlogo.ico"
                    ConvertTo-Icon -bitmapPath "$env:TEMP\cttlogo.png" -iconPath $iconPath
                }
            }
        }

    $FileBrowser = New-Object System.Windows.Forms.SaveFileDialog
    $FileBrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    $FileBrowser.Filter = "Shortcut Files (*.lnk)|*.lnk"
    $FileBrowser.FileName = $DestinationName
    $FileBrowser.ShowDialog() | Out-Null

    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($FileBrowser.FileName)
    $Shortcut.TargetPath = $SourceExe
    $Shortcut.Arguments = $ArgumentsToSourceExe
    if ($null -ne $iconPath) {
        $shortcut.IconLocation = $iconPath
    }
    $Shortcut.Save()

    if ($RunAsAdmin -eq $true) {
        $bytes = [System.IO.File]::ReadAllBytes($FileBrowser.FileName)
        # Set byte value at position 0x15 in hex, or 21 in decimal, from the value 0x00 to 0x20 in hex
        $bytes[0x15] = $bytes[0x15] -bor 0x20
        [System.IO.File]::WriteAllBytes($FileBrowser.FileName, $bytes)
    }

    Write-Host "Shortcut for $ShortcutToAdd has been saved to $($FileBrowser.FileName) with 'Run as administrator' set to $RunAsAdmin"
}