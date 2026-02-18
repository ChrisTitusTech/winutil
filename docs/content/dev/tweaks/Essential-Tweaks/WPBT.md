---
title: "Disable Windows Platform Binary Table (WPBT)"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1892}
  "WPFTweaksWPBT": {
    "Content": "Disable Windows Platform Binary Table (WPBT)",
    "Description": "If enabled then allows your computer vendor to execute a program each time it boots. It enables computer vendors to force install anti-theft software, software drivers, or a software program conveniently. This could also be a security risk.",
    "category": "Essential Tweaks",
    "panel": "1",
    "registry": [
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager",
        "Name": "DisableWpbtExecution",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
