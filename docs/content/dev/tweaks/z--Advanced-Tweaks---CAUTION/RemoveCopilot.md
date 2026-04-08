---
title: "Remove Microsoft Copilot"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1789}
  "WPFTweaksRemoveCopilot": {
    "Content": "Remove Microsoft Copilot",
    "Description": "Removes Copilot AppXPackages and related ai packages",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "InvokeScript": [
      "
      Get-AppxPackage -AllUsers *Copilot* | Remove-AppxPackage -AllUsers
      Get-AppxPackage -AllUsers Microsoft.MicrosoftOfficeHub | Remove-AppxPackage -AllUsers

      $Appx = (Get-AppxPackage MicrosoftWindows.Client.CoreAI).PackageFullName
      $Sid = (Get-LocalUser $Env:UserName).Sid.Value

      New-Item \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore\\EndOfLife\\$Sid\\$Appx\" -Force
      Remove-AppxPackage $Appx

      Write-Host \"Copilot Removed\"
      "
    ],
    "UndoScript": [
      "
      Write-Host \"Installing Copilot...\"
      winget install --name Copilot --source msstore --accept-package-agreements --accept-source-agreements --silent
      "
    ],
```
