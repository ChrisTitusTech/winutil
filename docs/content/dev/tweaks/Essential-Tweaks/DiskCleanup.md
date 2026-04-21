---
title: "Disk Cleanup - Run"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1074}
  "WPFTweaksDiskCleanup": {
    "Content": "Disk Cleanup - Run",
    "Description": "Runs Disk Cleanup on Drive C: and removes old Windows Updates.",
    "category": "Essential Tweaks",
    "panel": "1",
    "InvokeScript": [
      "
      cleanmgr.exe /d C: /VERYLOWDISK
      Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
      "
    ],
```
