---
title: "Widgets Button in Taskbar"
description: ""
---
```json
 "WPFToggleTaskbarWidgets": {
    "Content": "Widgets Button in Taskbar",
    "Description": "If Enabled then Widgets Button in Taskbar will be shown.",
    "category": "Customize Preferences",
    "panel": "2",
    "Order": "a204_",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "Name": "TaskbarDa",
        "Value": "1",
        "OriginalValue": "0",
        "DefaultState": "true",
        "Type": "DWord"
      }
    ],
```

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
