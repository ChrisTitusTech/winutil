# Sticky Keys

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

If Enabled then Sticky Keys is activated - Sticky keys is an accessibility feature of some graphical user interfaces which assists users who have physical disabilities or help users reduce repetitive strain injury.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Sticky Keys",
    "Description":  "If Enabled then Sticky Keys is activated - Sticky keys is an accessibility feature of some graphical user interfaces which assists users who have physical disabilities or help users reduce repetitive strain injury.",
    "link":  "https://christitustech.github.io/winutil/dev/tweaks/Shortcuts/Shortcut",
    "category":  "Customize Preferences",
    "panel":  "2",
    "Order":  "a108_",
    "Type":  "Toggle"
}
```
</details>

## Function: Invoke-WinUtilStickyKeys
```powershell
Function Invoke-WinUtilStickyKeys {
    <#
    .SYNOPSIS
        Disables/Enables Sticky Keyss on startup
    .PARAMETER Enabled
        Indicates whether to enable or disable Sticky Keys on startup
    #>
    Param($Enabled)
    Try {
        if ($Enabled -eq $false){
            Write-Host "Enabling Sticky Keys On startup"
            $value = 510
        }
        else {
            Write-Host "Disabling Sticky Keys On startup"
            $value = 58
        }
        $Path = "HKCU:\Control Panel\Accessibility\StickyKeys"
        Set-ItemProperty -Path $Path -Name Flags -Value $value
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

