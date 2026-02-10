---
title: "Snap Assist Suggestion"
description: ""
---
```json
"WPFToggleSnapSuggestion": {
    "Content": "Snap Assist Suggestion",
    "Description": "If enabled then you will get suggestions to snap other applications in the left over spaces.",
    "category": "Customize Preferences",
    "panel": "2",
    "Order": "a108_",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "Name": "SnapAssist",
        "Value": "1",
        "OriginalValue": "0",
        "DefaultState": "true",
        "Type": "DWord"
      }
    ],
    "InvokeScript": [
      "
      Invoke-WinUtilExplorerUpdate -action \"restart\"
      "
    ],
    "UndoScript": [
      "
      Invoke-WinUtilExplorerUpdate -action \"restart\"
      "
    ],
```

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
