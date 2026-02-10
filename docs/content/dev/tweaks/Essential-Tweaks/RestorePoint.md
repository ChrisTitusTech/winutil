---
title: "Create Restore Point"
description: ""
---
```json
"WPFTweaksRestorePoint": {
    "Content": "Create Restore Point",
    "Description": "Creates a restore point at runtime in case a revert is needed from WinUtil modifications",
    "category": "Essential Tweaks",
    "panel": "1",
    "Checked": "False",
    "Order": "a001_",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\SystemRestore",
        "Name": "SystemRestorePointCreationFrequency",
        "Type": "DWord",
        "Value": "0",
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
