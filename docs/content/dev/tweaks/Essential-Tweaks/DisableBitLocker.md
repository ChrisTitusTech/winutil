---
title: "BitLocker - Disable"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=604}
  "WPFTweaksDisableBitLocker": {
    "Content": "BitLocker - Disable",
    "Description": "Disables BitLocker.",
    "category": "Essential Tweaks",
    "panel": "1",
    "InvokeScript": [
      "Disable-BitLocker -MountPoint $Env:SystemDrive"
    ],
    "UndoScript": [
      "Enable-BitLocker -MountPoint $Env:SystemDrive"
    ],
```
