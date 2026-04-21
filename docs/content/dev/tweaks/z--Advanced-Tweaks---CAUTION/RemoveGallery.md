---
title: "File Explorer Gallery - Disable"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=640}
  "WPFTweaksRemoveGallery": {
    "Content": "File Explorer Gallery - Disable",
    "Description": "Removes the Gallery from Explorer and sets This PC as default.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "InvokeScript": [
      "
      Remove-Item \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Desktop\\NameSpace\\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}\"
      "
    ],
    "UndoScript": [
      "
      New-Item \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Desktop\\NameSpace\\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}\"
      "
    ],
```
