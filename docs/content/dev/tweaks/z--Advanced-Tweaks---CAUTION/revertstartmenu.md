---
title: "Revert the new start menu"
description: ""
---

```json
  "WPFTweaksRevertStartMenu": {
    "Content": "Revert the new start menu",
    "Description": "Uses vivetool to revert the the original start menu from 24h2",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "InvokeScript": [
      "
      Invoke-WebRequest https://github.com/thebookisclosed/ViVe/releases/download/v0.3.4/ViVeTool-v0.3.4-IntelAmd.zip -OutFile ViVeTool.zip
      
      Expand-Archive ViVeTool.zip
      Remove-Item ViVeTool.zip
      
      ViVeTool\\ViVeTool.exe /disable /id:47205210
      
      Remove-Item ViVeTool -Recurse

      Write-Host 'Old start menu reverted please restart your computer to take effect'
      "
    ],
    "UndoScript": [
      "
      Invoke-WebRequest https://github.com/thebookisclosed/ViVe/releases/download/v0.3.4/ViVeTool-v0.3.4-IntelAmd.zip -OutFile ViVeTool.zip
      
      Expand-Archive ViVeTool.zip
      Remove-Item ViVeTool.zip
      
      ViVeTool\\ViVeTool.exe /enable /id:47205210
      
      Remove-Item ViVeTool -Recurse

      Write-Host 'New start menu reverted please restart your computer to take effect'
      "
    ],
```
