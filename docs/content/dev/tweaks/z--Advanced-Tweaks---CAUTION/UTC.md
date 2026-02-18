---
title: "Set Time to UTC (Dual Boot)"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1445}
  "WPFTweaksUTC": {
    "Content": "Set Time to UTC (Dual Boot)",
    "Description": "Essential for computers that are dual booting. Fixes the time sync with Linux Systems.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "registry": [
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\TimeZoneInformation",
        "Name": "RealTimeIsUniversal",
        "Value": "1",
        "Type": "QWord",
        "OriginalValue": "0"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
