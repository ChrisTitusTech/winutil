---
title: "Windows Restore"
description: ""
---

```json {filename="config/feature.json",linenos=inline,linenostart=248}
  "WPFPanelRestore": {
    "Content": "Windows Restore",
    "category": "Legacy Windows Panels",
    "panel": "2",
    "Type": "Button",
    "ButtonWidth": "300",
    "InvokeScript": [
      "rstrui.exe"
    ],
```
