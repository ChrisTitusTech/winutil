# Sticky Keys

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

If Enabled then Sticky Keys is activated - Sticky keys is an accessibility feature of some graphical user interfaces which assists users who have physical disabilities or help users reduce repetitive strain injury.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Sticky Keys",
  "Description": "If Enabled then Sticky Keys is activated - Sticky keys is an accessibility feature of some graphical user interfaces which assists users who have physical disabilities or help users reduce repetitive strain injury.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a108_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Customize-Preferences/StickyKeys"
}
```

</details>

## Function: Invoke-WinutilStickyKeys

```powershell
Function Invoke-WinutilStickyKeys {
    <#
    .SYNOPSIS
        Disables/Enables Sticky Keyss on startup
    .PARAMETER Enabled
        Indicates whether to enable or disable Sticky Keys on startup
    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Enabling Sticky Keys On startup"
            $value = 510
        } else {
            Write-Host "Disabling Sticky Keys On startup"
            $value = 58
        }
        $Path = "HKCU:\Control Panel\Accessibility\StickyKeys"
        Set-ItemProperty -Path $Path -Name Flags -Value $value
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

