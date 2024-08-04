# Enable Legacy F8 Boot Recovery

Last Updated: 2024-08-04


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Enables Advanced Boot Options screen that lets you start Windows in advanced troubleshooting modes.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Enable Legacy F8 Boot Recovery",
    "Description":  "Enables Advanced Boot Options screen that lets you start Windows in advanced troubleshooting modes.",
    "category":  "Features",
    "panel":  "1",
    "Order":  "a018_",
    "feature":  [

                ],
    "InvokeScript":  [
                         "
      If (!(Test-Path \u0027HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager\\LastKnownGood\u0027)) {
            New-Item -Path \u0027HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager\\LastKnownGood\u0027 -Force | Out-Null
      }
      New-ItemProperty -Path \u0027HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager\\LastKnownGood\u0027 -Name \u0027Enabled\u0027 -Type DWord -Value 1 -Force
      Start-Process -FilePath cmd.exe -ArgumentList \u0027/c bcdedit /Set {Current} BootMenuPolicy Legacy\u0027 -Wait
      "
                     ]
}
```
</details>

## Invoke Script

```powershell

      If (!(Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager\LastKnownGood')) {
            New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager\LastKnownGood' -Force | Out-Null
      }
      New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager\LastKnownGood' -Name 'Enabled' -Type DWord -Value 1 -Force
      Start-Process -FilePath cmd.exe -ArgumentList '/c bcdedit /Set {Current} BootMenuPolicy Legacy' -Wait
      

```
<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)

