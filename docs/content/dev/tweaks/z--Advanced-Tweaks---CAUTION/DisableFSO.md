---
title: "Disable Fullscreen Optimizations"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=2127}
  "WPFTweaksDisableFSO": {
    "Content": "Disable Fullscreen Optimizations",
    "Description": "Disables FSO in all applications. NOTE: This will disable Color Management in Exclusive Fullscreen",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "registry": [
      {
        "Path": "HKCU:\\System\\GameConfigStore",
        "Name": "GameDVR_DXGIHonorFSEWindowsCompatible",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "0"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
