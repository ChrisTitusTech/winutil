# Disable Legacy F8 Boot Recovery


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a bit part of the dev-docs stays up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


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
    "\r\n      If (!(Test-Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager\\LastKnownGood')) {\r\n            New-Item -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager\\LastKnownGood' -Force | Out-Null\r\n      }\r\n      New-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager\\LastKnownGood' -Name 'Enabled' -Type DWord -Value 0 -Force\r\n      Start-Process -FilePath cmd.exe -ArgumentList '/c bcdedit /Set {Current} BootMenuPolicy Standard' -Wait\r\n      "
  ]
}
```
</details>



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)

