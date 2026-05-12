---
title: "Windows AI - Disable"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=964}
  "WPFTweaksWindowsAI": {
    "Content": "Windows AI - Disable",
    "Description": "Removes or disables all ai features and packages",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
        "Name": "SettingsPageVisibility",
        "Value": "hide:aicomponents",
        "Type": "String",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\WindowsNotepad",
        "Name": "DisableAIFeatures",
        "Value": 1,
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      }
    ],
    "InvokeScript": [
      "
      $Appx = (Get-AppxPackage MicrosoftWindows.Client.CoreAI).PackageFullName
      $Sid = (Get-LocalUser $Env:UserName).Sid.Value

      New-Item \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore\\EndOfLife\\$Sid\\$Appx\" -Force

      Get-AppxPackage -AllUsers *Copilot* | Remove-AppxPackage -AllUsers
      Get-AppxPackage -AllUsers Microsoft.MicrosoftOfficeHub | Remove-AppxPackage -AllUsers
      Remove-AppxPackage $Appx

      Set-Service -Name WSAIFabricSvc -StartupType Disabled
      Disable-WindowsOptionalFeature -FeatureName Recall -Online

      Write-Host \"Windows AI Disabled\"
      "
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify Windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
