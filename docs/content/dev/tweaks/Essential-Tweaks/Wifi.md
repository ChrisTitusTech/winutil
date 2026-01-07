# Disable Wifi-Sense

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Wifi Sense is a spying service that phones home all nearby scanned wifi networks and your current geo location.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Disable Wifi-Sense",
  "Description": "Wifi Sense is a spying service that phones home all nearby scanned wifi networks and your current geo location.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a005_",
  "registry": [
    {
      "Path": "HKLM:\\Software\\Microsoft\\PolicyManager\\default\\WiFi\\AllowWiFiHotSpotReporting",
      "Name": "Value",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\Software\\Microsoft\\PolicyManager\\default\\WiFi\\AllowAutoConnectToWiFiSenseHotspots",
      "Name": "Value",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    }
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/Wifi"
}
```

</details>

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.


You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).

### Registry Key: Value

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: Value

**Type:** DWord

**Original Value:** 1

**New Value:** 0



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

