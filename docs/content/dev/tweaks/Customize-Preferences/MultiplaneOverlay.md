---
title: "Disable Multiplane Overlay"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=2403}
  "WPFToggleMultiplaneOverlay": {
    "Content": "Disable Multiplane Overlay",
    "Description": "Disable the Multiplane Overlay which can sometimes cause issues with Graphics Cards.",
    "category": "Customize Preferences",
    "panel": "2",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\Dwm",
        "Name": "OverlayTestMode",
        "Value": "5",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>",
        "DefaultState": "false"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
