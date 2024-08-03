# Disable Search Box Web Suggestions in Registry(explorer restart)

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Disables web suggestions when searching using Windows Search.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Disable Search Box Web Suggestions in Registry(explorer restart)",
    "Description":  "Disables web suggestions when searching using Windows Search.",
    "link":  "https://christitustech.github.io/winutil/dev/features/Legacy-Windows-Panels/user",
    "category":  "Features",
    "panel":  "1",
    "Order":  "a016_",
    "feature":  [

                ],
    "InvokeScript":  [
                         "\r\n      If (!(Test-Path \u0027HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer\u0027)) {\r\n            New-Item -Path \u0027HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer\u0027 -Force | Out-Null\r\n      }\r\n      New-ItemProperty -Path \u0027HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer\u0027 -Name \u0027DisableSearchBoxSuggestions\u0027 -Type DWord -Value 1 -Force\r\n      Stop-Process -name explorer -force\r\n      "
                     ]
}
```
</details>

## Invoke Script

```powershell

      If (!(Test-Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer')) {
            New-Item -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Force | Out-Null
      }
      New-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Type DWord -Value 1 -Force
      Stop-Process -name explorer -force
      

```
<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)

