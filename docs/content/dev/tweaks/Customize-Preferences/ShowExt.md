# Show File Extensions

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

If enabled then File extensions (e.g., .txt, .jpg) are visible.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Show File Extensions",
  "Description": "If enabled then File extensions (e.g., .txt, .jpg) are visible.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a201_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Customize-Preferences/ShowExt"
}
```

</details>

## Function: Invoke-WinutilShowExt

```powershell
function Invoke-WinutilShowExt {
    <#
    .SYNOPSIS
        Disables/Enables Show file Extentions
    .PARAMETER Enabled
        Indicates whether to enable or disable Show file extentions
    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Showing file extentions"
            $value = 0
        } else {
            Write-Host "hiding file extensions"
            $value = 1
        }
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $Path -Name HideFileExt -Value $value
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

