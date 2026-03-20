---
title: "Revert Start Menu layout"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=90}
  "WPFTweaksRevertStartMenu": {
    "Content": "Revert Start Menu layout",
    "Description": "Bring back the old Start Menu layout from before the gradual rollout of the new one in 25H2.",
    "category": "Essential Tweaks",
    "panel": "1",
    "InvokeScript": [
      "
      Invoke-WebRequest https://github.com/thebookisclosed/ViVe/releases/download/v0.3.4/ViVeTool-v0.3.4-IntelAmd.zip -OutFile ViVeTool.zip

      Expand-Archive ViVeTool.zip
      Remove-Item ViVeTool.zip

      Start-Process 'ViVeTool\\ViVeTool.exe' -ArgumentList '/disable /id:47205210' -Wait -NoNewWindow

      Remove-Item ViVeTool -Recurse

      Write-Host 'Old start menu reverted please restart your computer to take effect'
      "
    ],
    "UndoScript": [
      "
      Invoke-WebRequest https://github.com/thebookisclosed/ViVe/releases/download/v0.3.4/ViVeTool-v0.3.4-IntelAmd.zip -OutFile ViVeTool.zip

      Expand-Archive ViVeTool.zip
      Remove-Item ViVeTool.zip

      Start-Process 'ViVeTool\\ViVeTool.exe' -ArgumentList '/enable /id:47205210' -Wait -NoNewWindow

      Remove-Item ViVeTool -Recurse

      Write-Host 'New start menu reverted please restart your computer to take effect'
      "
    ],
```
