---
title: "Remove Xbox & Gaming Components"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1633}
  "WPFTweaksXboxRemoval": {
    "Content": "Remove Xbox & Gaming Components",
    "Description": "Removes Xbox services, the Xbox app, Game Bar, and related authentication components.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "appx": [
      "Microsoft.XboxIdentityProvider",
      "Microsoft.XboxSpeechToTextOverlay",
      "Microsoft.GamingApp",
      "Microsoft.Xbox.TCUI",
      "Microsoft.XboxGamingOverlay"
    ],
```
