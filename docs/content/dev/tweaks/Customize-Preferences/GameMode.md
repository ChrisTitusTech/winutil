---
title: "Game Mode"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1817}
  "WPFToggleGameMode": {
    "Content": "Game Mode",
    "Description": "Toggles Windows prioritizes gaming performance by allocating system resources to games.",
    "category": "Customize Preferences",
    "panel": "2",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKCU:\\Software\\Microsoft\\GameBar",
        "Name": "AllowAutoGameMode",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "0",
        "DefaultState": "true"
      },
      {
        "Path": "HKCU:\\Software\\Microsoft\\GameBar",
        "Name": "AutoGameModeEnabled",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "0",
        "DefaultState": "true"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify Windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://en.wikipedia.org/wiki/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
