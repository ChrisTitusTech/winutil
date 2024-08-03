# Disable Powershell 7 Telemetry

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

This will create an Environment Variable called 'POWERSHELL_TELEMETRY_OPTOUT' with a value of '1' which will tell Powershell 7 to not send Telemetry Data.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Disable Powershell 7 Telemetry",
    "Description":  "This will create an Environment Variable called \u0027POWERSHELL_TELEMETRY_OPTOUT\u0027 with a value of \u00271\u0027 which will tell Powershell 7 to not send Telemetry Data.",
    "link":  "https://christitustech.github.io/winutil/dev/tweaks/Shortcuts/Shortcut",
    "category":  "Essential Tweaks",
    "panel":  "1",
    "Order":  "a009_",
    "InvokeScript":  [
                         "[Environment]::SetEnvironmentVariable(\u0027POWERSHELL_TELEMETRY_OPTOUT\u0027, \u00271\u0027, \u0027Machine\u0027)"
                     ],
    "UndoScript":  [
                       "[Environment]::SetEnvironmentVariable(\u0027POWERSHELL_TELEMETRY_OPTOUT\u0027, \u0027\u0027, \u0027Machine\u0027)"
                   ]
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

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

