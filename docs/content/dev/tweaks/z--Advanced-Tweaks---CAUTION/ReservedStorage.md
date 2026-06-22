---
title: "Disable Reserved Storage"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=870}
  "WPFTweaksReservedStorage": {
    "Content": "Disable Reserved Storage",
    "Description": "Disables Windows Reserved Storage (7-10 GB held for updates/temp files). Recommended only on small drives. Re-enable before major Windows feature updates to avoid installation failures.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "InvokeScript": [
      "DISM /Online /Set-ReservedStorageState /State:Disabled"
    ],
    "UndoScript": [
      "DISM /Online /Set-ReservedStorageState /State:Enabled"
    ],
```
