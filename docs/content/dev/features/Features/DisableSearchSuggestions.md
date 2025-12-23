# Disable Search Box Web Suggestions in Registry(explorer restart)

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Disables web suggestions when searching using Windows Search.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Disable Search Box Web Suggestions in Registry(explorer restart)",
  "Description": "Disables web suggestions when searching using Windows Search.",
  "category": "Features",
  "panel": "1",
  "Order": "a016_",
  "feature": [],
  "InvokeScript": [
    "
      If (!(Test-Path 'HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer')) {
            New-Item -Path 'HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer' -Force | Out-Null
      }
      New-ItemProperty -Path 'HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer' -Name 'DisableSearchBoxSuggestions' -Type DWord -Value 1 -Force
      Stop-Process -name explorer -force
      "
  ],
  "link": "https://christitustech.github.io/Winutil/dev/features/Features/DisableSearchSuggestions"
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


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/feature.json)

