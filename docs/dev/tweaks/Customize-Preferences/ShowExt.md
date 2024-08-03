# Show File Extensions

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

If enabled then File extensions (e.g., .txt, .jpg) are visible.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Show File Extensions",
    "Description":  "If enabled then File extensions (e.g., .txt, .jpg) are visible.",
    "link":  "https://christitustech.github.io/winutil/dev/tweaks/Shortcuts/Shortcut",
    "category":  "Customize Preferences",
    "panel":  "2",
    "Order":  "a201_",
    "Type":  "Toggle"
}
```
</details>

## Function: Invoke-WinUtilShowExt
```powershell
function Invoke-WinUtilShowExt {
    <#
    .SYNOPSIS
        Disables/Enables Show file Extentions
    .PARAMETER Enabled
        Indicates whether to enable or disable Show file extentions
    #>
    Param($Enabled)
    Try{
        if ($Enabled -eq $false){
            Write-Host "Showing file extentions"
            $value = 0
        }
        else {
            Write-Host "hiding file extensions"
            $value = 1
        }
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $Path -Name HideFileExt -Value $value
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

