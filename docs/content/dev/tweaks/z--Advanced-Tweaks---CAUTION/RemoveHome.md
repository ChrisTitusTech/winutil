---
title: "File Explorer Home - Disable"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=644}
  "WPFTweaksRemoveHome": {
    "Content": "File Explorer Home - Disable",
    "Description": "Removes the Home from Explorer and sets This PC as default.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "InvokeScript": [
      "
      Remove-Item \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Desktop\\NameSpace\\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}\"
      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\" -Name LaunchTo -Value 1
      "
    ],
    "UndoScript": [
      "
      New-Item \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Desktop\\NameSpace\\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}\"
      Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\" -Name LaunchTo -Value 0
      "
    ],
```
