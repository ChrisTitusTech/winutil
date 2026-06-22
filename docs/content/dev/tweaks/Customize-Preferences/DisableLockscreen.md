---
title: "Lock Screen - Disable"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1674}
  "WPFTweaksDisableLockscreen": {
    "Content": "Lock Screen - Disable",
    "Description": "Skips the lock screen entirely and goes directly to the sign-in screen on boot and wake.",
    "category": "Customize Preferences",
    "panel": "2",
    "Type": "Toggle",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Personalization",
        "Name": "NoLockScreen",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify Windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://en.wikipedia.org/wiki/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
