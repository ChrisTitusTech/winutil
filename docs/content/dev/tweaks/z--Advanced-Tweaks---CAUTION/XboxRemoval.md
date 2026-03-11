---
title: "Remove Xbox & Gaming Components"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1646}
  "WPFTweaksXboxRemoval": {
    "Content": "Remove Xbox & Gaming Components",
    "Description": "Removes Xbox services, the Xbox app, Game Bar, and related authentication components.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "registry": [
      {
        "Path": "KCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\GameDVR",
        "Name": "AppCaptureEnabled",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "1"
      }
    ],
    "appx": [
      "Microsoft.XboxIdentityProvider",
      "Microsoft.XboxSpeechToTextOverlay",
      "Microsoft.GamingApp",
      "Microsoft.Xbox.TCUI",
      "Microsoft.XboxGamingOverlay"
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
