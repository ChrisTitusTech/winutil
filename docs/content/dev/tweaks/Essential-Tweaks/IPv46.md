# Prefer IPv4 over IPv6

Last Updated: 2024-08-27


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

To set the IPv4 preference can have latency and security benefits on private networks where IPv6 is not configured.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Prefer IPv4 over IPv6",
  "Description": "To set the IPv4 preference can have latency and security benefits on private networks where IPv6 is not configured.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a005_",
  "registry": [
    {
      "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip6\\Parameters",
      "Name": "DisabledComponents",
      "Value": "32",
      "OriginalValue": "0",
      "Type": "DWord"
    }
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/IPv46"
}
```

</details>

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.


You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).

### Registry Key: DisabledComponents

**Type:** DWord

**Original Value:** 0

**New Value:** 32



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

