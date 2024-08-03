# Search Button in Taskbar

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

If Enabled Search Button will be on the taskbar.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Search Button in Taskbar",
    "Description":  "If Enabled Search Button will be on the taskbar.",
    "link":  "https://christitustech.github.io/winutil/dev/tweaks/Shortcuts/Shortcut",
    "category":  "Customize Preferences",
    "panel":  "2",
    "Order":  "a202_",
    "Type":  "Toggle"
}
```
</details>

## Function: Invoke-WinUtilTaskbarSearch
```powershell
function Invoke-WinUtilTaskbarSearch {
    <#

    .SYNOPSIS
        Enable/Disable Taskbar Search Button.

    .PARAMETER Enabled
        Indicates whether to enable or disable Taskbar Search Button.

    #>
    Param($Enabled)
    Try{
        if ($Enabled -eq $false){
            Write-Host "Enabling Search Button"
            $value = 1
        }
        else {
            Write-Host "Disabling Search Button"
            $value = 0
        }
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\"
        Set-ItemProperty -Path $Path -Name SearchboxTaskbarMode -Value $value
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

