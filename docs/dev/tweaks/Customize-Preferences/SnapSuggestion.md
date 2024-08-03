# Snap Assist Suggestion

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

If enabled then you will get suggestions to snap other applications in the left over spaces.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Snap Assist Suggestion",
    "Description":  "If enabled then you will get suggestions to snap other applications in the left over spaces.",
    "link":  "https://christitustech.github.io/winutil/dev/tweaks/Shortcuts/Shortcut",
    "category":  "Customize Preferences",
    "panel":  "2",
    "Order":  "a106_",
    "Type":  "Toggle"
}
```
</details>

## Function: Invoke-WinUtilSnapSuggestion
```powershell
function Invoke-WinUtilSnapSuggestion {
    <#
    .SYNOPSIS
        Disables/Enables Snap Assist Suggestions on startup
    .PARAMETER Enabled
        Indicates whether to enable or disable Snap Assist Suggestions on startup
    #>
    Param($Enabled)
    Try{
        if ($Enabled -eq $false){
            Write-Host "Enabling Snap Assist Suggestion On startup"
            $value = 1
        }
        else {
            Write-Host "Disabling Snap Assist Suggestion On startup"
            $value = 0
        }
        # taskkill.exe /F /IM "explorer.exe"
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        taskkill.exe /F /IM "explorer.exe"
        Set-ItemProperty -Path $Path -Name SnapAssist -Value $value
        Start-Process "explorer.exe"
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

