---
title: "Detailed BSoD"
description: ""
---
```json
"WPFToggleDetailedBSoD": {
    "Content": "Detailed BSoD",
    "Description": "If Enabled then you will see a detailed Blue Screen of Death (BSOD) with more information.",
    "category": "Customize Preferences",
    "panel": "2",
    "Order": "a205_",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\CrashControl",
        "Name": "DisplayParameters",
        "Value": "1",
        "OriginalValue": "0",
        "DefaultState": "false",
        "Type": "DWord"
      },
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\CrashControl",
        "Name": "DisableEmoticon",
        "Value": "1",
        "OriginalValue": "0",
        "DefaultState": "false",
        "Type": "DWord"
      }
    ],
```

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
