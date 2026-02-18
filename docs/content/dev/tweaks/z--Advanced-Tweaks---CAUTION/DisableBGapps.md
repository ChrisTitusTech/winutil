---
title: "Disable Background Apps"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=2111}
  "WPFTweaksDisableBGapps": {
    "Content": "Disable Background Apps",
    "Description": "Disables all Microsoft Store apps from running in the background, which has to be done individually since Win11",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "registry": [
      {
        "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications",
        "Name": "GlobalUserDisabled",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "0"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
