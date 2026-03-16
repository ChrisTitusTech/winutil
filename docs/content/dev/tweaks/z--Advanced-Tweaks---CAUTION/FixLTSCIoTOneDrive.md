---
title: "Fix OneDrive Explorer Integration on Win10/11 LTSC and IoT"
description: "Fixes OneDrive integration in File Explorer on Windows 10/11 LTSC and IoT editions by re-registering the OneDrive Shell Extension."
---

```json {filename="config/tweaks.json",linenos=inline,linenostart=1830}
  "WPFTweaksFixLTSCIoTOneDrive": {
    "Content": "Fix OneDrive Explorer Integration on Win10/11 LTSC and IoT",
    "Description": "Fixes OneDrive integration in File Explorer on Windows 10/11 LTSC and IoT editions by re-registering the OneDrive Shell Extension.",
    "category": "z__Advanced Tweaks - CAUTION",
    "panel": "1",
    "registry": [
        {
          "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions\\{A52BBA46-E9E1-435f-B3D9-28DAA648C0F6}",
          "Name": "Attributes",
          "Value": "1",
          "Type": "DWord",
          "OriginalValue": "<RemoveEntry>"
        },
        {
          "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions\\{A52BBA46-E9E1-435f-B3D9-28DAA648C0F6}",
          "Name": "Category",
          "Value": "4",
          "Type": "DWord",
          "OriginalValue": "<RemoveEntry>"
        },
        {
          "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions\\{A52BBA46-E9E1-435f-B3D9-28DAA648C0F6}",
          "Name": "DefinitionFlags",
          "Value": "64",
          "Type": "DWord",
          "OriginalValue": "<RemoveEntry>"
        },
        {
          "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions\\{A52BBA46-E9E1-435f-B3D9-28DAA648C0F6}",
          "Name": "Icon",
          "Value": "%SystemRoot%\\system32\\imageres.dll,-1040",
          "Type": "ExpandString",
          "OriginalValue": "<RemoveEntry>"
        },
        {
          "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions\\{A52BBA46-E9E1-435f-B3D9-28DAA648C0F6}",
          "Name": "LocalizedName",
          "Value": "@%SystemRoot%\\System32\\SettingSyncCore.dll,-1024",
          "Type": "ExpandString",
          "OriginalValue": "<RemoveEntry>"
        },
        {
          "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions\\{A52BBA46-E9E1-435f-B3D9-28DAA648C0F6}",
          "Name": "LocalRedirectOnly",
          "Value": "1",
          "Type": "DWord",
          "OriginalValue": "<RemoveEntry>"
        },
        {
          "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions\\{A52BBA46-E9E1-435f-B3D9-28DAA648C0F6}",
          "Name": "Name",
          "Value": "OneDrive",
          "Type": "String",
          "OriginalValue": "<RemoveEntry>"
        },
        {
          "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions\\{A52BBA46-E9E1-435f-B3D9-28DAA648C0F6}",
          "Name": "ParentFolder",
          "Value": "{5E6C858F-0E22-4760-9AFE-EA3317B67173}",
          "Type": "String",
          "OriginalValue": "<RemoveEntry>"
        },
        {
          "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions\\{A52BBA46-E9E1-435f-B3D9-28DAA648C0F6}",
          "Name": "ParsingName",
          "Value": "shell:::{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
          "Type": "String",
          "OriginalValue": "<RemoveEntry>"
        },
        {
          "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions\\{A52BBA46-E9E1-435f-B3D9-28DAA648C0F6}",
          "Name": "RelativePath",
          "Value": "OneDrive",
          "Type": "String",
          "OriginalValue": "<RemoveEntry>"
        }
    ]
  },
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
