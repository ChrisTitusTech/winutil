---
title: "Enable Legacy F8 Boot Recovery"
description: ""
---

```json {filename="config/feature.json",linenos=inline,linenostart=89}
  "WPFFeatureEnableLegacyRecovery": {
    "Content": "Enable Legacy F8 Boot Recovery",
    "Description": "Enables Advanced Boot Options screen that lets you start Windows in advanced troubleshooting modes.",
    "category": "Features",
    "panel": "1",
    "feature": [],
    "InvokeScript": [
      "bcdedit /set bootmenupolicy legacy"
    ],
```
