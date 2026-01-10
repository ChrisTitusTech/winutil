# Disable Powershell 7 Telemetry

```json
"WPFTweaksPowershell7Tele": {
    "Content": "Disable Powershell 7 Telemetry",
    "Description": "This will create an Environment Variable called 'POWERSHELL_TELEMETRY_OPTOUT' with a value of '1' which will tell Powershell 7 to not send Telemetry Data.",
    "category": "Essential Tweaks",
    "panel": "1",
    "Order": "a005_",
    "InvokeScript": [
      "[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')"
    ],
    "UndoScript": [
      "[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '', 'Machine')"
    ],
```
