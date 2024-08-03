# Widgets Button in Taskbar

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

If Enabled then Widgets Button in Taskbar will be shown.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Widgets Button in Taskbar",
    "Description":  "If Enabled then Widgets Button in Taskbar will be shown.",
    "link":  "https://christitustech.github.io/winutil/dev/tweaks/Shortcuts/Shortcut",
    "category":  "Customize Preferences",
    "panel":  "2",
    "Order":  "a204_",
    "Type":  "Toggle"
}
```
</details>

## Function: Invoke-WinUtilTaskbarWidgets
```powershell
function Invoke-WinUtilTaskbarWidgets {
    <#

    .SYNOPSIS
        Enable/Disable Taskbar Widgets

    .PARAMETER Enabled
        Indicates whether to enable or disable Taskbar Widgets

    #>
    Param($Enabled)
    Try{
        if ($Enabled -eq $false){
            Write-Host "Enabling Taskbar Widgets"
            $value = 1
        }
        else {
            Write-Host "Disabling Taskbar Widgets"
            $value = 0
        }
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $Path -Name TaskbarDa -Value $value
    }
    Catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $Value due to a Security Exception"
    }
    Catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    }
    Catch{
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

