# Dark Theme for Windows

Last Updated: 2024-10-01


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Enable/Disable Dark Mode.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Dark Theme for Windows",
  "Description": "Enable/Disable Dark Mode.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a100_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Customize-Preferences/DarkMode"
}
```

</details>

## Function: Invoke-WinUtilDarkMode

```powershell
Function Invoke-WinUtilDarkMode {
    <#

    .SYNOPSIS
        Enables/Disables Dark Mode

    .PARAMETER DarkMoveEnabled
        Indicates the current dark mode state

    #>
    Param($DarkMoveEnabled)
    try {
        if ($DarkMoveEnabled -eq $false) {
            Write-Host "Enabling Dark Mode"
            $DarkMoveValue = 0
        } else {
            Write-Host "Disabling Dark Mode"
            $DarkMoveValue = 1
        }

        $Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        Set-ItemProperty -Path $Path -Name AppsUseLightTheme -Value $DarkMoveValue
        Set-ItemProperty -Path $Path -Name SystemUsesLightTheme -Value $DarkMoveValue
        Invoke-WinUtilExplorerRefresh
        # Update Winutil Theme if the Theme Button shows the Icon for Auto
        if ($sync.ThemeButton.Content -eq [char]0xF08C) {
            Invoke-WinutilThemeChange -theme "Auto"
        }
    } catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $Value due to a Security Exception"
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    } catch {
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

