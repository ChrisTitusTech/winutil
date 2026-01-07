# Disable Fullscreen Optimizations

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Disables FSO in all applications. NOTE: This will disable Color Management in Exclusive Fullscreen

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Disable Fullscreen Optimizations",
  "Description": "Disables FSO in all applications. NOTE: This will disable Color Management in Exclusive Fullscreen",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a024_",
  "registry": [
    {
      "Path": "HKCU:\\System\\GameConfigStore",
      "Name": "GameDVR_DXGIHonorFSEWindowsCompatible",
      "Value": "1",
      "OriginalValue": "0",
      "Type": "DWord"
    }
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/DisableFSO"
}
```

</details>

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.


You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).

### Registry Key: GameDVR_DXGIHonorFSEWindowsCompatible

**Type:** DWord

**Original Value:** 0

**New Value:** 1



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

