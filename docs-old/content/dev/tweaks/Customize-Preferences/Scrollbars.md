---
title: "Scrollbars Always Visible"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1444}
    "WPFToggleScrollbars": {
    "Content": "Scrollbars Always Visible",
    "Description": "If enabled, scrollbars will always be visible. If disabled, Windows will automatically hide scrollbars when not in use.",
    "category": "Customize Preferences",
    "panel": "2",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKCU:\\Control Panel\\Accessibility",
        "Name": "DynamicScrollbars",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "1",
        "DefaultState": "false",
      "link": "https://winutil.christitus.com/dev/tweaks/customize-preferences/scrollbars"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify Windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://en.wikipedia.org/wiki/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
