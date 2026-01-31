---
title: "Disable ConsumerFeatures"
description: ""
---
```json
  "WPFTweaksConsumerFeatures": {
    "Content": "Disable ConsumerFeatures",
    "Description": "Windows will not automatically install any games, third-party apps, or application links from the Windows Store for the signed-in user. Some default Apps will be inaccessible (eg. Phone Link)",
    "category": "Essential Tweaks",
    "panel": "1",
    "Order": "a003_",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent",
        "OriginalValue": "<RemoveEntry>",
        "Name": "DisableWindowsConsumerFeatures",
        "Value": "1",
        "Type": "DWord"
      }
    ],
```

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
