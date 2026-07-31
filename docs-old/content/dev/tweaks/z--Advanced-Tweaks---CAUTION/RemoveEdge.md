---
title: "Microsoft Edge - Remove"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=587}
  "WPFTweaksRemoveEdge": {
    "Content": "Microsoft Edge - Remove",
    "Description": "Uninstalls Microsoft Edge by creating dummy MicrosoftEdge.exe file in the legacy Edge folder. This tricks Windows into unlocking the official Edge uninstaller allowing for a system-level removal.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "InvokeScript": [
      "
      $Path = Resolve-Path -Path \"$Env:ProgramFiles (x86)\\Microsoft\\Edge\\Application\\*\\Installer\\setup.exe\" | Select-Object -Last 1

      if (Test-Path $Path) {
          New-Item -Path \"$Env:SystemRoot\\SystemApps\\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\\MicrosoftEdge.exe\" -Force
          Start-Process -FilePath $Path -ArgumentList \"--uninstall --system-level --force-uninstall --delete-profile\" -Wait
          Write-Host \"Microsoft Edge was removed\"
      } else {
          Write-Host \"Microsoft Edge is not installed\"
      }
      "
    ],
    "UndoScript": [
      "
      Write-Host \"Installing Microsoft Edge...\"
      winget install Microsoft.Edge --source winget
      "
    ],
```
