---
title: "Brave Debloat"
description: ""
---

```json
  "WPFTweaksBraveDebloat": {
    "Content": "Brave Debloat",
    "Description": "Disables various annoyances like Brave Rewards,Leo AI,Crypto Wallet and VPN",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "Order": "a022_",
    "registry": [
      {
        "Path":"HKLM:\\SOFTWARE\\Policies\\BraveSoftware\\Brave",
        "Name": "BraveRewardsDisabled",
        "Type": "DWord",
        "Value": "1",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\BraveSoftware\\Brave",
        "Name": "BraveWalletDisabled",
        "Type": "DWord",
        "Value": "1",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\BraveSoftware\\Brave",
        "Name": "BraveVPNDisabled",
        "Type": "DWord",
        "Value": "1",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\BraveSoftware\\Brave",
        "Name": "BraveAIChatEnabled",
        "Type": "DWord",
        "Value": "0",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\BraveSoftware\\Brave",
        "Name": "BraveStatsPingEnabled",
        "Type": "DWord",
        "Value": "0",
        "OriginalValue": "<RemoveEntry>"
      }
    ],
```
