---
title: "S3 Sleep"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=2567}
  "WPFToggleS3Sleep": {
    "Content": "S3 Sleep",
    "Description": "Toggles between Modern Standby and S3 sleep.",
    "category": "Customize Preferences",
    "panel": "2",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Power",
        "Name": "PlatformAoAcOverride",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>",
        "DefaultState": "false"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
