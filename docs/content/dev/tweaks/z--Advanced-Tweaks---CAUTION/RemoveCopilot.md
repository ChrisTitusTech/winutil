---
title: "Disable Microsoft Copilot"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1808}
  "WPFTweaksRemoveCopilot": {
    "Content": "Disable Microsoft Copilot",
    "Description": "Disables MS Copilot AI built into Windows since 23H2.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsCopilot",
        "Name": "TurnOffWindowsCopilot",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKCU:\\Software\\Policies\\Microsoft\\Windows\\WindowsCopilot",
        "Name": "TurnOffWindowsCopilot",
        "Value": "1",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
        "Name": "ShowCopilotButton",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "1"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\Shell\\Copilot",
        "Name": "IsCopilotAvailable",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\Shell\\Copilot",
        "Name": "CopilotDisabledReason",
        "Value": "IsEnabledForGeographicRegionFailed",
        "Type": "String",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\WindowsCopilot",
        "Name": "AllowCopilotRuntime",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Shell Extensions\\Blocked",
        "Name": "{CB3B0003-8088-4EDE-8769-8B354AB2FF8C}",
        "Value": "",
        "Type": "String",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\Shell\\Copilot\\BingChat",
        "Name": "IsUserEligible",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      }
    ],
    "InvokeScript": [
      "
      Write-Host \"Remove Copilot\"
      Get-AppxPackage -AllUsers *Copilot* | Remove-AppxPackage -AllUsers
      Get-AppxPackage -AllUsers Microsoft.MicrosoftOfficeHub | Remove-AppxPackage -AllUsers

      $Appx = (Get-AppxPackage MicrosoftWindows.Client.CoreAI).PackageFullName

      $Sid = (Get-LocalUser $Env:UserName).Sid.Value
      New-Item \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Appx\\AppxAllUserStore\\EndOfLife\\$Sid\\$Appx\" -Force
      Remove-AppxPackage $Appx
      "
    ],
    "UndoScript": [
      "
      Write-Host \"Install Copilot\"
      winget install --name Copilot --source msstore --accept-package-agreements --accept-source-agreements --silent
      "
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
