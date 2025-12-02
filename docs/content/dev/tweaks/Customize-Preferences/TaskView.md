# Task View Button in Taskbar

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

If Enabled then Task View Button in Taskbar will be shown.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Task View Button in Taskbar",
  "Description": "If Enabled then Task View Button in Taskbar will be shown.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a203_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Customize-Preferences/TaskView"
}
```

</details>

## Function: Invoke-WinutilTaskView

```powershell
function Invoke-WinutilTaskView {
    <#

    .SYNOPSIS
        Enable/Disable Task View

    .PARAMETER Enabled
        Indicates whether to enable or disable Task View

    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Enabling Task View"
            $value = 1
        } else {
            Write-Host "Disabling Task View"
            $value = 0
        }
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $Path -Name ShowTaskViewButton -Value $value
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

