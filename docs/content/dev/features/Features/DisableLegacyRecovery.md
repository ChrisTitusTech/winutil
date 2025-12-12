# Disable Legacy F8 Boot Recovery

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Disables Advanced Boot Options screen that lets you start Windows in advanced troubleshooting modes.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Disable Legacy F8 Boot Recovery",
  "Description": "Disables Advanced Boot Options screen that lets you start Windows in advanced troubleshooting modes.",
  "category": "Features",
  "panel": "1",
  "Order": "a019_",
  "feature": [],
  "InvokeScript": [
    "
      If (!(Test-Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager\\LastKnownGood')) {
            New-Item -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager\\LastKnownGood' -Force | Out-Null
      }
      New-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager\\LastKnownGood' -Name 'Enabled' -Type DWord -Value 0 -Force
      Start-Process -FilePath cmd.exe -ArgumentList '/c bcdedit /Set {Current} BootMenuPolicy Standard' -Wait
      "
  ],
  "link": "https://christitustech.github.io/Winutil/dev/features/Features/DisableLegacyRecovery"
}
```

</details>

## Invoke Script

```powershell

      If (!(Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager\LastKnownGood')) {
            New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager\LastKnownGood' -Force | Out-Null
      }
      New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager\LastKnownGood' -Name 'Enabled' -Type DWord -Value 0 -Force
      Start-Process -FilePath cmd.exe -ArgumentList '/c bcdedit /Set {Current} BootMenuPolicy Standard' -Wait


```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/feature.json)

