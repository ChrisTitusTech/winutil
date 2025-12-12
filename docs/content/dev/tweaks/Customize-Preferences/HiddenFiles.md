# Show Hidden Files

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

If Enabled then Hidden Files will be shown.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Show Hidden Files",
  "Description": "If Enabled then Hidden Files will be shown.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a200_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Customize-Preferences/HiddenFiles"
}
```

</details>

## Function: Invoke-WinutilHiddenFiles

```powershell
function Invoke-WinutilHiddenFiles {
    <#

    .SYNOPSIS
        Enable/Disable Hidden Files

    .PARAMETER Enabled
        Indicates whether to enable or disable Hidden Files

    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Enabling Hidden Files"
            $value = 1
        } else {
            Write-Host "Disabling Hidden Files"
            $value = 0
        }
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $Path -Name Hidden -Value $value
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

