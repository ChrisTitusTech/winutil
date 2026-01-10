# Remove Microsoft Edge

```json
"WPFTweaksMakeEdgeUninstallable": {
    "Content": "Make Edge Uninstallable via settings",
    "Description": "Makes it so you can uninstall edge via settings > installed apps",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "Order": "a026_",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Microsoft Edge",
        "Name": "NoRemove",
        "Type": "Dword",
        "Value": "0",
        "OriginalValue": "1"
      }
    ],
    "InvokeScript": [
      "
      $File = \"C:\\Windows\\System32\\IntegratedServicesRegionPolicySet.json\"

      takeown /f $File
      icacls $File /grant \"Administrators:(F)\"

      $FileContent = Get-Content $File
      $FileContent[7] = $FileContent[7] -replace \"disabled\", \"enabled\"
      Set-Content $File $FileContent
      "
    ],
    "UndoScript": [
      "
      $File = \"C:\\Windows\\System32\\IntegratedServicesRegionPolicySet.json\"

      takeown /f $File
      icacls $File /grant \"Administrators:(F)\"

      $FileContent = Get-Content $File
      $FileContent[7] = $FileContent[7] -replace \"enabled\", \"disabled\"
      Set-Content $File $FileContent
      "
    ],
```

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
