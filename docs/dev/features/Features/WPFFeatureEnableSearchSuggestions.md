# Enable Search Box Web Suggestions in Registry(explorer restart)


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a bit part of the dev-docs stays up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Enables web suggestions when searching using Windows Search.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Enable Search Box Web Suggestions in Registry(explorer restart)",
    "Description":  "Enables web suggestions when searching using Windows Search.",
    "category":  "Features",
    "panel":  "1",
    "Order":  "a015_",
    "feature":  [

                ],
    "InvokeScript":  [
                         "\r\n      If (!(Test-Path \u0027HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer\u0027)) {\r\n            New-Item -Path \u0027HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer\u0027 -Force | Out-Null\r\n      }\r\n      New-ItemProperty -Path \u0027HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer\u0027 -Name \u0027DisableSearchBoxSuggestions\u0027 -Type DWord -Value 0 -Force\r\n      Stop-Process -name explorer -force\r\n      "
                     ]
}
```
</details>

## Invoke Script

```json

      If (!(Test-Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer')) {
            New-Item -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Force | Out-Null
      }
      New-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Type DWord -Value 0 -Force
      Stop-Process -name explorer -force
      

```



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)

