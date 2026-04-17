---
title: "Legacy F8 Boot Recovery - Disable"
description: ""
---

```json {filename="config/feature.json",linenos=inline,linenostart=110}
  "WPFFeatureDisableLegacyRecovery": {
    "Content": "Legacy F8 Boot Recovery - Disable",
    "Description": "Disables Advanced Boot Options screen that lets you start Windows in advanced troubleshooting modes.",
    "category": "Features",
    "panel": "1",
    "feature": [],
    "InvokeScript": [
      "bcdedit /set bootmenupolicy standard"
    ],
```
