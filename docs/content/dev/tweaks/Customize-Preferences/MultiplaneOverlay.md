---
title: "Multiplane Overlay"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=2271}
  "WPFToggleMultiplaneOverlay": {
    "Content": "Multiplane Overlay",
    "Description": "Enable or disable the Multiplane Overlay, which can sometimes cause issues with graphics cards.",
    "category": "Customize Preferences",
    "panel": "2",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\Dwm",
        "Name": "OverlayTestMode",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "5",
        "DefaultState": "true"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify Windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
