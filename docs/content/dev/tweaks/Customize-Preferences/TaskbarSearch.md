# Search Button in Taskbar

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

If Enabled Search Button will be on the taskbar.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Search Button in Taskbar",
  "Description": "If Enabled Search Button will be on the taskbar.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a202_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Customize-Preferences/TaskbarSearch"
}
```

</details>

## Function: Invoke-WinutilTaskbarSearch

```powershell
function Invoke-WinutilTaskbarSearch {
    <#

    .SYNOPSIS
        Enable/Disable Taskbar Search Button.

    .PARAMETER Enabled
        Indicates whether to enable or disable Taskbar Search Button.

    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Enabling Search Button"
            $value = 1
        } else {
            Write-Host "Disabling Search Button"
            $value = 0
        }
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search\"
        Set-ItemProperty -Path $Path -Name SearchboxTaskbarMode -Value $value
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


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

