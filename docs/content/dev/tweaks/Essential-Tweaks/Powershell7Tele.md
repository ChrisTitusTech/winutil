# Disable Powershell 7 Telemetry

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
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
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/Powershell7Tele"
}
```

</details>

## Invoke Script

```powershell
[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')

```
## Undo Script

```powershell
[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '', 'Machine')

```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

