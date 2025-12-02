# Center Taskbar Items

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

[Windows 11] If Enabled then the Taskbar Items will be shown on the Center, otherwise the Taskbar Items will be shown on the Left.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Center Taskbar Items",
  "Description": "[Windows 11] If Enabled then the Taskbar Items will be shown on the Center, otherwise the Taskbar Items will be shown on the Left.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a204_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Customize-Preferences/TaskbarAlignment"
}
```

</details>

## Function: Invoke-WinutilTaskbarAlignment

```powershell
function Invoke-WinutilTaskbarAlignment {
    <#

    .SYNOPSIS
        Switches between Center & Left Taskbar Alignment

    .PARAMETER Enabled
        Indicates whether to make Taskbar Alignment Center or Left

    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Making Taskbar Alignment to the Center"
            $value = 1
        } else {
            Write-Host "Making Taskbar Alignment to the Left"
            $value = 0
        }
        $Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $Path -Name "TaskbarAl" -Value $value
    } catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $value due to a Security Exception"
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

