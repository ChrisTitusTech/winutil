---
title: "Remove OneDrive"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1461}
  "WPFTweaksRemoveOneDrive": {
    "Content": "Remove OneDrive",
    "Description": "Denys permission to remove onedrive user files than uses its own uninstaller to remove it than brings back permissions",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "InvokeScript": [
      "
      # Deny permission to remove OneDrive folder
      icacls $Env:OneDrive /deny \"Administrators:(D,DC)\"

      Write-Host \"Uninstalling OneDrive...\"
      Start-Process 'C:\\Windows\\System32\\OneDriveSetup.exe' -ArgumentList '/uninstall' -Wait

      # Some of OneDrive files use explorer, and OneDrive uses FileCoAuth
      Write-Host \"Removing leftover OneDrive Files...\"
      Stop-Process -Name FileCoAuth,Explorer
      Remove-Item \"$Env:LocalAppData\\Microsoft\\OneDrive\" -Recurse -Force
      Remove-Item \"C:\\ProgramData\\Microsoft OneDrive\" -Recurse -Force

      # Grant back permission to accses OneDrive folder
      icacls $Env:OneDrive /grant \"Administrators:(D,DC)\"

      # Disable OneSyncSvc
      Set-Service -Name OneSyncSvc -StartupType Disabled
      "
    ],
    "UndoScript": [
      "
      Write-Host \"Installing OneDrive\"
      winget install Microsoft.Onedrive --source winget

      # Enabled OneSyncSvc
      Set-Service -Name OneSyncSvc -StartupType Enabled
      "
    ],
```
