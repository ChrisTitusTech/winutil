---
title: "Remove Settings Home Page"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=2291}
  "WPFToggleHideSettingsHome": {
    "Content": "Remove Settings Home Page",
    "Description": "Removes the Home page in the Windows Settings app.",
    "category": "Customize Preferences",
    "panel": "2",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
        "Name": "SettingsPageVisibility",
        "Value": "hide:home",
        "Type": "String",
        "OriginalValue": "show:home",
        "DefaultState": "false"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
