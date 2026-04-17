---
title: "Acrylic Blur on Login Screen"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=2191}
  "WPFToggleLoginBlur": {
    "Content": "Acrylic Blur on Login Screen",
    "Description": "If disabled, the acrylic blur effect will be removed on the Windows 10/11 login screen background.",
    "category": "Customize Preferences",
    "panel": "2",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
        "Name": "DisableAcrylicBackgroundOnLogon",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "1",
        "DefaultState": "true"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify Windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
