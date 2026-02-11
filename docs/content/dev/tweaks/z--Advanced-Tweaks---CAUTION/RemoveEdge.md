---
title: "Remove Microsoft Edge"
description: ""
---
# Json File
```json {filename="config/tweaks.json",linenos=inline,linenostart=1446}
  "WPFTweaksRemoveEdge": {
    "Content": "Remove Microsoft Edge",
    "Description": "Unblocks Microsoft Edge uninstaller restrictions than uses that uninstaller to remove Microsoft Edge",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "InvokeScript": [
      "Invoke-WinUtilRemoveEdge"
    ],
    "UndoScript": [
      "
      Write-Host 'Installing Microsoft Edge...'
      winget install Microsoft.Edge --source winget
      "
    ],
```
# Function
```powershell {filename="functions/public/Invoke-WinUtilRemoveEdge.ps1",linenos=inline,linenostart=1}
function Invoke-WinUtilRemoveEdge {
  Write-Host "Unlocking The Offical Edge Uninstaller And Removing Microsoft Edge..."

  $Path = (Get-ChildItem "C:\Program Files (x86)\Microsoft\Edge\Application\*\Installer\setup.exe")[0].FullName
  New-Item "C:\Windows\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe\MicrosoftEdge.exe" -Force
  Start-Process $Path -ArgumentList '--uninstall --system-level --force-uninstall --delete-profile'
}
```
