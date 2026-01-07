# NumLock on Startup

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Toggle the Num Lock key state when your computer starts.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "NumLock on Startup",
  "Description": "Toggle the Num Lock key state when your computer starts.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a102_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Customize-Preferences/NumLock"
}
```

</details>

## Function: Invoke-WinutilNumLock

```powershell
function Invoke-WinutilNumLock {
    <#
    .SYNOPSIS
        Disables/Enables NumLock on startup
    .PARAMETER Enabled
        Indicates whether to enable or disable Numlock on startup
    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Enabling Numlock on startup"
            $value = 2
        } else {
            Write-Host "Disabling Numlock on startup"
            $value = 0
        }
        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
        $HKUPath = "HKU:\.Default\Control Panel\Keyboard"
        $HKCUPath = "HKCU:\Control Panel\Keyboard"
        Set-ItemProperty -Path $HKUPath -Name InitialKeyboardIndicators -Value $value
        Set-ItemProperty -Path $HKCUPath -Name InitialKeyboardIndicators -Value $value
    }
    Catch [System.Security.SecurityException] {
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

