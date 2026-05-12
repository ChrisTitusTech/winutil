---
title: "Temporary Files - Remove"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1136}
  "WPFTweaksDeleteTempFiles": {
    "Content": "Temporary Files - Remove",
    "Description": "Erases TEMP Folders.",
    "category": "Essential Tweaks",
    "panel": "1",
    "InvokeScript": [
      "
      Remove-Item -Path \"$Env:Temp\\*\" -Recurse -Force
      Remove-Item -Path \"$Env:SystemRoot\\Temp\\*\" -Recurse -Force
      "
    ],
```
