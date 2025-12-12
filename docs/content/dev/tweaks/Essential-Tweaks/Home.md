# Disable Homegroup

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Disables HomeGroup - HomeGroup is a password-protected home networking service that lets you share your stuff with other PCs that are currently running and connected to your network.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Disable Homegroup",
  "Description": "Disables HomeGroup - HomeGroup is a password-protected home networking service that lets you share your stuff with other PCs that are currently running and connected to your network.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a005_",
  "service": [
    {
      "Name": "HomeGroupListener",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "HomeGroupProvider",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    }
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/Home"
}
```

</details>

## Service Changes

Windows services are background processes for system functions or applications. Setting some to manual optimizes performance by starting them only when needed.

You can find information about services on [Wikipedia](https://www.wikiwand.com/en/Windows_service) and [Microsoft's Website](https://learn.microsoft.com/en-us/dotnet/framework/windows-services/introduction-to-windows-service-applications).

### Service Name: HomeGroupListener

**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: HomeGroupProvider

**Startup Type:** Manual

**Original Type:** Automatic



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

