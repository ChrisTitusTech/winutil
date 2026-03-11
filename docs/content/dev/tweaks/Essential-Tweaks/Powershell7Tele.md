---
title: "Disable Powershell 7 Telemetry"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1801}
  "WPFTweaksPowershell7Tele": {
    "Content": "Disable Powershell 7 Telemetry",
    "Description": "Creates an Environment Variable called 'POWERSHELL_TELEMETRY_OPTOUT' with a value of '1' which will tell PowerShell 7 to not send Telemetry Data.",
    "category": "Essential Tweaks",
    "panel": "1",
    "InvokeScript": [
      "[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')"
    ],
    "UndoScript": [
      "[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '', 'Machine')"
    ],
```
