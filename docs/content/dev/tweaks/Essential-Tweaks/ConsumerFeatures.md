---
title: "Disable ConsumerFeatures"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1291}
  "WPFTweaksConsumerFeatures": {
    "Content": "Disable ConsumerFeatures",
    "Description": "Windows will not automatically install any games, third-party apps, or application links from the Windows Store for the signed-in user. Some default Apps will be inaccessible (eg. Phone Link)",
    "category": "Essential Tweaks",
    "panel": "1",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent",
        "Name": "DisableWindowsConsumerFeatures",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
