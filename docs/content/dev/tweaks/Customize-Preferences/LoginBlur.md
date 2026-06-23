---
title: "Logon Screen Acrylic Blur"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1656}
  "WPFToggleLoginBlur": {
    "Content": "Logon Screen Acrylic Blur",
    "Description": "Toggles the acrylic blur effect on login screen background.",
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

You can find information about the registry on [Wikipedia](https://en.wikipedia.org/wiki/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
