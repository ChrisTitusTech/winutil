# Disable Powershell 7 Telemetry


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a bit part of the dev-docs stays up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

This will create an Environment Variable called 'POWERSHELL_TELEMETRY_OPTOUT' with a value of '1' which will tell Powershell 7 to not send Telemetry Data.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Disable Powershell 7 Telemetry",
  "Description": "This will create an Environment Variable called 'POWERSHELL_TELEMETRY_OPTOUT' with a value of '1' which will tell Powershell 7 to not send Telemetry Data.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a009_",
  "InvokeScript": [
    "[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')"
  ],
  "UndoScript": [
    "[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '', 'Machine')"
  ]
}
```
</details>



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

