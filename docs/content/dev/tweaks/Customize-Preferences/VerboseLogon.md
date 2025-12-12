# Verbose Messages During Logon

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Show detailed messages during the login process for troubleshooting and diagnostics.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Verbose Messages During Logon",
  "Description": "Show detailed messages during the login process for troubleshooting and diagnostics.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a103_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Customize-Preferences/VerboseLogon"
}
```

</details>

## Function: Invoke-WinutilVerboseLogon

```powershell
function Invoke-WinutilVerboseLogon {
    <#
    .SYNOPSIS
        Disables/Enables VerboseLogon Messages
    .PARAMETER Enabled
        Indicates whether to enable or disable VerboseLogon messages
    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Enabling Verbose Logon Messages"
            $value = 1
        } else {
            Write-Host "Disabling Verbose Logon Messages"
            $value = 0
        }
        $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Set-ItemProperty -Path $Path -Name VerboseStatus -Value $value
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

