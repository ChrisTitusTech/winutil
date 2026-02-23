---
title: "Disable Explorer Automatic Folder Discovery"
description: ""
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=2616}
  "WPFTweaksDisableExplorerAutoDiscovery": {
    "Content": "Disable Explorer Automatic Folder Discovery",
    "Description": "Windows Explorer automatically tries to guess the type of the folder based on its contents, slowing down the browsing experience. WARNING! Will disable file explorer grouping",
    "category": "Essential Tweaks",
    "panel": "1",
    "InvokeScript": [
      "
      # Previously detected folders
      $bags = \"HKCU:\\Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\Shell\\Bags\"

      # Folder types lookup table
      $bagMRU = \"HKCU:\\Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\Shell\\BagMRU\"

      # Flush Explorer view database
      Remove-Item -Path $bags -Recurse -Force
      Write-Host \"Removed $bags\"

      Remove-Item -Path $bagMRU -Recurse -Force
      Write-Host \"Removed $bagMRU\"

      # Every folder
      $allFolders = \"HKCU:\\Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\Shell\\Bags\\AllFolders\\Shell\"

      if (!(Test-Path $allFolders)) {
        New-Item -Path $allFolders -Force
        Write-Host \"Created $allFolders\"
      }

      # Generic view
      New-ItemProperty -Path $allFolders -Name \"FolderType\" -Value \"NotSpecified\" -PropertyType String -Force
      Write-Host \"Set FolderType to NotSpecified\"

      Write-Host Please sign out and back in, or restart your computer to apply the changes!
      "
    ],
    "UndoScript": [
      "
      # Previously detected folders
      $bags = \"HKCU:\\Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\Shell\\Bags\"

      # Folder types lookup table
      $bagMRU = \"HKCU:\\Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\Shell\\BagMRU\"

      # Flush Explorer view database
      Remove-Item -Path $bags -Recurse -Force
      Write-Host \"Removed $bags\"

      Remove-Item -Path $bagMRU -Recurse -Force
      Write-Host \"Removed $bagMRU\"

      Write-Host Please sign out and back in, or restart your computer to apply the changes!
      "
    ],
```
