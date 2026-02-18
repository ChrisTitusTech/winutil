---
title: "Create Restore Point"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1736}
  "WPFTweaksRestorePoint": {
    "Content": "Create Restore Point",
    "Description": "Creates a restore point at runtime in case a revert is needed from WinUtil modifications",
    "category": "Essential Tweaks",
    "panel": "1",
    "Checked": "False",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\SystemRestore",
        "Name": "SystemRestorePointCreationFrequency",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "1440"
      }
    ],
    "InvokeScript": [
      "
      if (-not (Get-ComputerRestorePoint)) {
          Enable-ComputerRestore -Drive $Env:SystemDrive
      }

      Checkpoint-Computer -Description \"System Restore Point created by WinUtil\" -RestorePointType MODIFY_SETTINGS
      Write-Host \"System Restore Point Created Successfully\" -ForegroundColor Green
      "
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
