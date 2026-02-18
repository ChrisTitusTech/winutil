---
title: "Sticky Keys"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=2343}
  "WPFToggleStickyKeys": {
    "Content": "Sticky Keys",
    "Description": "If Enabled then Sticky Keys is activated - Sticky keys is an accessibility feature of some graphical user interfaces which assists users who have physical disabilities or help users reduce repetitive strain injury.",
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

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
