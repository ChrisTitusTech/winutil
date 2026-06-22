---
title: "Right-Click Menu Previous Layout - Enable"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1088}
  "WPFTweaksRightClickMenu": {
    "Content": "Right-Click Menu Previous Layout - Enable",
    "Description": "Restores the classic context menu when right-clicking in File Explorer, replacing the simplified Windows 11 version.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "InvokeScript": [
      "
      New-Item -Path \"HKCU:\\Software\\Classes\\CLSID\\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\" -Name InprocServer32 -Value \"\" -Force
      Stop-Process -Name explorer
      "
    ],
    "UndoScript": [
      "Remove-Item -Path \"HKCU:\\Software\\Classes\\CLSID\\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\" -Recurse"
    ],
```
