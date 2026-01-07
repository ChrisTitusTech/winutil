# Disable GameDVR

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

GameDVR is a Windows App that is a dependency for some Store Games. I've never met someone that likes it, but it's there for the XBOX crowd.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Disable GameDVR",
  "Description": "GameDVR is a Windows App that is a dependency for some Store Games. I've never met someone that likes it, but it's there for the XBOX crowd.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a005_",
  "registry": [
    {
      "Path": "HKCU:\\System\\GameConfigStore",
      "Name": "GameDVR_FSEBehavior",
      "Value": "2",
      "OriginalValue": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\System\\GameConfigStore",
      "Name": "GameDVR_Enabled",
      "Value": "0",
      "OriginalValue": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\System\\GameConfigStore",
      "Name": "GameDVR_HonorUserFSEBehaviorMode",
      "Value": "1",
      "OriginalValue": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\System\\GameConfigStore",
      "Name": "GameDVR_EFSEFeatureFlags",
      "Value": "0",
      "OriginalValue": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\GameDVR",
      "Name": "AllowGameDVR",
      "Value": "0",
      "OriginalValue": "1",
      "Type": "DWord"
    }
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/DVR"
}
```

</details>

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.


You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).

### Registry Key: GameDVR_FSEBehavior

**Type:** DWord

**Original Value:** 1

**New Value:** 2

### Registry Key: GameDVR_Enabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: GameDVR_HonorUserFSEBehaviorMode

**Type:** DWord

**Original Value:** 0

**New Value:** 1

### Registry Key: GameDVR_EFSEFeatureFlags

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: AllowGameDVR

**Type:** DWord

**Original Value:** 1

**New Value:** 0



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

