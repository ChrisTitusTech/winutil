---
title: "Legacy F8 Boot Recovery - Enable"
description: ""
---

```json {filename="config/feature.json",linenos=inline,linenostart=99}
  "WPFFeatureEnableLegacyRecovery": {
    "Content": "Legacy F8 Boot Recovery - Enable",
    "Description": "Enables Advanced Boot Options screen that lets you start Windows in advanced troubleshooting modes.",
    "category": "Features",
    "panel": "1",
    "feature": [],
    "InvokeScript": [
      "bcdedit /set bootmenupolicy legacy"
    ],
```
