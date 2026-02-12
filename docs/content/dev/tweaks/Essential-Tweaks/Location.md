---
title: "Disable Location Tracking"
description: ""
---
```json {filename="config/tweaks.json",linenos=inline,linenostart=133}
  "WPFTweaksLocation": {
    "Content": "Disable Location Tracking",
    "Description": "Disables Location Tracking...DUH!",
    "category": "Essential Tweaks",
    "panel": "1",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\location",
        "Name": "Value",
        "Type": "String",
        "Value": "Deny",
        "OriginalValue": "Allow"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Sensor\\Overrides\\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}",
        "Name": "SensorPermissionState",
        "Type": "DWord",
        "Value": "0",
        "OriginalValue": "1"
      },
      {
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\lfsvc\\Service\\Configuration",
        "Name": "Status",
        "Type": "DWord",
        "Value": "0",
        "OriginalValue": "1"
      },
      {
        "Path": "HKLM:\\SYSTEM\\Maps",
        "Name": "AutoUpdateEnabled",
        "Type": "DWord",
        "Value": "0",
        "OriginalValue": "1"
      }
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
