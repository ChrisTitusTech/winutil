# Mouse Acceleration

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

If Enabled then Cursor movement is affected by the speed of your physical mouse movements.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Mouse Acceleration",
    "Description":  "If Enabled then Cursor movement is affected by the speed of your physical mouse movements.",
    "link":  "https://christitustech.github.io/winutil/dev/tweaks/Shortcuts/Shortcut",
    "category":  "Customize Preferences",
    "panel":  "2",
    "Order":  "a107_",
    "Type":  "Toggle"
}
```
</details>

## Function: Invoke-WinUtilMouseAcceleration
```powershell
Function Invoke-WinUtilMouseAcceleration {
    <#

    .SYNOPSIS
        Enables/Disables Mouse Acceleration

    .PARAMETER DarkMoveEnabled
        Indicates the current Mouse Acceleration State

    #>
    Param($MouseAccelerationEnabled)
    Try{
        if ($MouseAccelerationEnabled -eq $false){
            Write-Host "Enabling Mouse Acceleration"
            $MouseSpeed = 1
            $MouseThreshold1 = 6
            $MouseThreshold2 = 10
        }
        else {
            Write-Host "Disabling Mouse Acceleration"
            $MouseSpeed = 0
            $MouseThreshold1 = 0
            $MouseThreshold2 = 0

        }

        $Path = "HKCU:\Control Panel\Mouse"
        Set-ItemProperty -Path $Path -Name MouseSpeed -Value $MouseSpeed
        Set-ItemProperty -Path $Path -Name MouseThreshold1 -Value $MouseThreshold1
        Set-ItemProperty -Path $Path -Name MouseThreshold2 -Value $MouseThreshold2
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

