---
title: "Delivery Optimization - Disable"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=572}
  "WPFTweaksDeliveryOptimization": {
    "Content": "Delivery Optimization - Disable",
    "Description": "Stops Windows from using your bandwidth to upload updates to other PCs on the internet or local network.",
    "category": "Essential Tweaks",
    "panel": "1",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DeliveryOptimization",
        "Name": "DODownloadMode",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify Windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://en.wikipedia.org/wiki/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
