---
title: "Disable Legacy F8 Boot Recovery"
description: ""
---
```json
  "WPFFeatureDisableLegacyRecovery": {
    "Content": "Disable Legacy F8 Boot Recovery",
    "Description": "Disables Advanced Boot Options screen that lets you start Windows in advanced troubleshooting modes.",
    "category": "Features",
    "panel": "1",
    "Order": "a019_",
    "feature": [],
    "InvokeScript": [
    "bcdedit /set bootmenupolicy standard"
    ],
```
