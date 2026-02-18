---
title: "Brave Debloat"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1126}
  "WPFTweaksBraveDebloat": {
    "Content": "Brave Debloat",
    "Description": "Disables various annoyances like Brave Rewards,Leo AI,Crypto Wallet and VPN",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\BraveSoftware\\Brave",
        "Name": "BraveRewardsDisabled",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\BraveSoftware\\Brave",
        "Name": "BraveWalletDisabled",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\BraveSoftware\\Brave",
        "Name": "BraveVPNDisabled",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\BraveSoftware\\Brave",
        "Name": "BraveAIChatEnabled",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\BraveSoftware\\Brave",
        "Name": "BraveStatsPingEnabled",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
