function Invoke-WPFShortcut {
    <#

        .DESCRIPTION
        Creates a shortcut

    #>
    param($ShortcutToAdd)

    Switch ($ShortcutToAdd) {
        "WinUtil" {
            $SourceExe = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" 
            $IRM = 'irm https://christitus.com/win | iex'
            $Powershell = '-ExecutionPolicy Bypass -Command "Start-Process powershell.exe -verb runas -ArgumentList'
            $ArgumentsToSourceExe = "$powershell '$IRM'"
            $DestinationName = "WinUtil.lnk"
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
    $Shortcut.Save()
    
    Write-Host "Shortcut for $ShortcutToAdd has been saved to $($FileBrowser.FileName)"
}