# Create WinUtil Shortcut

Last Updated: 2024-08-07


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Create WinUtil Shortcut",
  "category": "Shortcuts",
  "panel": "2",
  "Order": "a082_",
  "Type": "Button",
  "ButtonWidth": "300",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Shortcuts/Shortcut"
}
```

</details>

## Function: Invoke-WPFShortcut

```powershell
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

    # Preper the Shortcut Fields and add an a Custom Icon if it's available, else don't add a Custom Icon.

    Switch ($ShortcutToAdd) {
        "WinUtil" {
            # Use Powershell 7 if installed and fallback to PS5 if not
            if (Get-Command "pwsh" -ErrorAction SilentlyContinue) {
                $shell = "pwsh.exe"
            } else {
                $shell = "powershell.exe"
            }

            $shellArgs = "-ExecutionPolicy Bypass -Command `"Start-Process $shell -verb runas -ArgumentList `'-Command `"irm https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1 | iex`"`'"

            $DestinationName = "WinUtil.lnk"
        }
    }

    # Show a File Dialog Browser, to let the User choose the Name and Location of where to save the Shortcut
    $FileBrowser = New-Object System.Windows.Forms.SaveFileDialog
    $FileBrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    $FileBrowser.Filter = "Shortcut Files (*.lnk)|*.lnk"
    $FileBrowser.FileName = $DestinationName

    # Do an Early Return if the Save Operation was canceled by User's Input.
    $FileBrowserResult = $FileBrowser.ShowDialog()
    $DialogResultEnum = New-Object System.Windows.Forms.DialogResult
    if (-not ($FileBrowserResult -eq $DialogResultEnum::OK)) {
        return
    }

    # Prepare the Shortcut paramter
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($FileBrowser.FileName)
    $Shortcut.TargetPath = $shell
    $Shortcut.Arguments = $shellArgs
    if (Test-Path -Path $winutildir["logo.ico"]) {
        $shortcut.IconLocation = $winutildir["logo.ico"]
    }

    # Save the Shortcut to disk
    $Shortcut.Save()

    if ($RunAsAdmin -eq $true) {
        $bytes = [System.IO.File]::ReadAllBytes($FileBrowser.FileName)
        # Set byte value at position 0x15 in hex, or 21 in decimal, from the value 0x00 to 0x20 in hex
        $bytes[0x15] = $bytes[0x15] -bor 0x20
        [System.IO.File]::WriteAllBytes($FileBrowser.FileName, $bytes)
    }

    Write-Host "Shortcut for $ShortcutToAdd has been saved to $($FileBrowser.FileName) with 'Run as administrator' set to $RunAsAdmin"
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

