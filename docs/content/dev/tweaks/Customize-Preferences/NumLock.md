---
title: "NumLock on Startup"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=2203}
  "WPFToggleNumLock": {
    "Content": "NumLock on Startup",
    "Description": "Toggle the Num Lock key state when your computer starts.",
    "category": "Customize Preferences",
    "panel": "2",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKU:\\.Default\\Control Panel\\Keyboard",
        "Name": "InitialKeyboardIndicators",
        "Value": "2",
        "Type": "DWord",
        "OriginalValue": "0",
        "DefaultState": "false"
      },
      {
        "Path": "HKCU:\\Control Panel\\Keyboard",
        "Name": "InitialKeyboardIndicators",
        "Value": "2",
        "Type": "DWord",
        "OriginalValue": "0",
        "DefaultState": "false"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
