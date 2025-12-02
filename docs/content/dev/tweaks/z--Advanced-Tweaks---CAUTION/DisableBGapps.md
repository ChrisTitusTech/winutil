# Disable Background Apps

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Disables all Microsoft Store apps from running in the background, which has to be done individually since Win11

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Disable Background Apps",
  "Description": "Disables all Microsoft Store apps from running in the background, which has to be done individually since Win11",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a024_",
  "registry": [
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\BackgroundAccessApplications",
      "Name": "GlobalUserDisabled",
      "Value": "1",
      "OriginalValue": "0",
      "Type": "DWord"
    }
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/DisableBGapps"
}
```

</details>

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.


You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).

### Registry Key: GlobalUserDisabled

**Type:** DWord

**Original Value:** 0

**New Value:** 1



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

