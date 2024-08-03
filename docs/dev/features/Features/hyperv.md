# HyperV Virtualization

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Hyper-V is a hardware virtualization product developed by Microsoft that allows users to create and manage virtual machines.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "HyperV Virtualization",
    "Description":  "Hyper-V is a hardware virtualization product developed by Microsoft that allows users to create and manage virtual machines.",
    "link":  "https://christitustech.github.io/winutil/dev/features/Legacy-Windows-Panels/user",
    "category":  "Features",
    "panel":  "1",
    "Order":  "a011_",
    "feature":  [
                    "HypervisorPlatform",
                    "Microsoft-Hyper-V-All",
                    "Microsoft-Hyper-V",
                    "Microsoft-Hyper-V-Tools-All",
                    "Microsoft-Hyper-V-Management-PowerShell",
                    "Microsoft-Hyper-V-Hypervisor",
                    "Microsoft-Hyper-V-Services",
                    "Microsoft-Hyper-V-Management-Clients"
                ],
    "InvokeScript":  [
                         "Start-Process -FilePath cmd.exe -ArgumentList \u0027/c bcdedit /set hypervisorschedulertype classic\u0027 -Wait"
                     ]
}
```
</details>

## Invoke Script

```powershell
Start-Process -FilePath cmd.exe -ArgumentList '/c bcdedit /set hypervisorschedulertype classic' -Wait

```
<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)

