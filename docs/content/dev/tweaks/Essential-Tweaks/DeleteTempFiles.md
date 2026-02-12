---
title: "Delete Temporary Files"
description: ""
---
```json {filename="config/tweaks.json",linenos=inline,linenostart=2047}
  "WPFTweaksDeleteTempFiles": {
    "Content": "Delete Temporary Files",
    "Description": "Erases TEMP Folders",
    "category": "Essential Tweaks",
    "panel": "1",
    "InvokeScript": [
      "
      Remove-Item -Path \"$Env:Temp\\*\" -Recurse -Force
      Remove-Item -Path \"$Env:SystemRoot\\Temp\\*\" -Recurse -Force
      "
    ],
```
