# Disable Location Tracking

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Disables Location Tracking...DUH!

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Disable Location Tracking",
  "Description": "Disables Location Tracking...DUH!",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a005_",
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
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/Loc"
}
```

</details>

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.


You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).

### Registry Key: Value

**Type:** String

**Original Value:** Allow

**New Value:** Deny

### Registry Key: SensorPermissionState

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: Status

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: AutoUpdateEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

