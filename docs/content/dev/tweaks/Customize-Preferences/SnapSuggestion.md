# Snap Assist Suggestion

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

If enabled then you will get suggestions to snap other applications in the left over spaces.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Snap Assist Suggestion",
  "Description": "If enabled then you will get suggestions to snap other applications in the left over spaces.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a106_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Customize-Preferences/SnapSuggestion"
}
```

</details>

## Function: Invoke-WinutilSnapSuggestion

```powershell
function Invoke-WinutilSnapSuggestion {
    <#
    .SYNOPSIS
        Disables/Enables Snap Assist Suggestions on startup
    .PARAMETER Enabled
        Indicates whether to enable or disable Snap Assist Suggestions on startup
    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Enabling Snap Assist Suggestion On startup"
            $value = 1
        } else {
            Write-Host "Disabling Snap Assist Suggestion On startup"
            $value = 0
        }
        # taskkill.exe /F /IM "explorer.exe"
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        taskkill.exe /F /IM "explorer.exe"
        Set-ItemProperty -Path $Path -Name SnapAssist -Value $value
        Start-Process "explorer.exe"
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

