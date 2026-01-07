# HyperV Virtualization

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Hyper-V is a hardware virtualization product developed by Microsoft that allows users to create and manage virtual machines.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "HyperV Virtualization",
  "Description": "Hyper-V is a hardware virtualization product developed by Microsoft that allows users to create and manage virtual machines.",
  "category": "Features",
  "panel": "1",
  "Order": "a011_",
  "feature": [
    "HypervisorPlatform",
    "Microsoft-Hyper-V-All",
    "Microsoft-Hyper-V",
    "Microsoft-Hyper-V-Tools-All",
    "Microsoft-Hyper-V-Management-PowerShell",
    "Microsoft-Hyper-V-Hypervisor",
    "Microsoft-Hyper-V-Services",
    "Microsoft-Hyper-V-Management-Clients"
  ],
  "InvokeScript": [
    "Start-Process -FilePath cmd.exe -ArgumentList '/c bcdedit /set hypervisorschedulertype classic' -Wait"
  ],
  "link": "https://christitustech.github.io/Winutil/dev/features/Features/hyperv"
}
```

</details>

## Features


Optional Windows Features are additional functionalities or components in the Windows operating system that users can choose to enable or disable based on their specific needs and preferences.


You can find information about Optional Windows Features on [Microsoft's Website for Optional Features](https://learn.microsoft.com/en-us/windows/client-management/client-tools/add-remove-hide-features?pivots=windows-11).

### Features to install
- HypervisorPlatform
- Microsoft-Hyper-V-All
- Microsoft-Hyper-V
- Microsoft-Hyper-V-Tools-All
- Microsoft-Hyper-V-Management-PowerShell
- Microsoft-Hyper-V-Hypervisor
- Microsoft-Hyper-V-Services
- Microsoft-Hyper-V-Management-Clients

## Invoke Script

```powershell
Start-Process -FilePath cmd.exe -ArgumentList '/c bcdedit /set hypervisorschedulertype classic' -Wait

```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/feature.json)

