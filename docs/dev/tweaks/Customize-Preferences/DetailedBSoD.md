# Detailed BSoD

Last Updated: 2024-08-07


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

If Enabled then you will see a detailed Blue Screen of Death (BSOD) with more information.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Detailed BSoD",
  "Description": "If Enabled then you will see a detailed Blue Screen of Death (BSOD) with more information.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a205_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Customize-Preferences/DetailedBSoD"
}
```

</details>

## Function: Invoke-WinUtilDetailedBSoD

```powershell
Function Invoke-WinUtilDetailedBSoD {
    <#

    .SYNOPSIS
        Enables/Disables Detailed BSoD
        (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Name 'DisplayParameters').DisplayParameters


    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Enabling Detailed BSoD"
            $value = 1
        } else {
            Write-Host "Disabling Detailed BSoD"
            $value =0
        }

        $Path = "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl"
        Set-ItemProperty -Path $Path -Name DisplayParameters -Value $value
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

