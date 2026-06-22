---
title: "Sticky Keys"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1735}
  "WPFToggleStickyKeys": {
    "Content": "Sticky Keys",
    "Description": "Toggles the Sticky Keys, which activate when clicking shift rapidly.",
    "category": "Customize Preferences",
    "panel": "2",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKCU:\\Control Panel\\Accessibility\\StickyKeys",
        "Name": "Flags",
        "Value": "506",
        "Type": "DWord",
        "OriginalValue": "58",
        "DefaultState": "true"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify Windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://en.wikipedia.org/wiki/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
