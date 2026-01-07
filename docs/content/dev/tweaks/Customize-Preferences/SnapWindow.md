# Snap Window

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

If enabled you can align windows by dragging them. | Relogin Required

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Snap Window",
  "Description": "If enabled you can align windows by dragging them. | Relogin Required",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a104_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Customize-Preferences/SnapWindow"
}
```

</details>

## Function: Invoke-WinutilSnapWindow

```powershell
function Invoke-WinutilSnapWindow {
    <#
    .SYNOPSIS
        Disables/Enables Snapping Windows on startup
    .PARAMETER Enabled
        Indicates whether to enable or disable Snapping Windows on startup
    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Enabling Snap Windows On startup | Relogin Required"
            $value = 1
        } else {
            Write-Host "Disabling Snap Windows On startup | Relogin Required"
            $value = 0
        }
        $Path = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $Path -Name WindowArrangementActive -Value $value
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

