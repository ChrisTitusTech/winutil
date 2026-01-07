# NFS - Network File System

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Network File System (NFS) is a mechanism for storing files on a network.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "NFS - Network File System",
  "Description": "Network File System (NFS) is a mechanism for storing files on a network.",
  "category": "Features",
  "panel": "1",
  "Order": "a014_",
  "feature": [
    "ServicesForNFS-ClientOnly",
    "ClientForNFS-Infrastructure",
    "NFS-Administration"
  ],
  "InvokeScript": [
    "nfsadmin client stop",
    "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\ClientForNFS\\CurrentVersion\\Default' -Name 'AnonymousUID' -Type DWord -Value 0",
    "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\ClientForNFS\\CurrentVersion\\Default' -Name 'AnonymousGID' -Type DWord -Value 0",
    "nfsadmin client start",
    "nfsadmin client localhost config fileaccess=755 SecFlavors=+sys -krb5 -krb5i"
  ],
  "link": "https://christitustech.github.io/Winutil/dev/features/Features/nfs"
}
```

</details>

## Features


Optional Windows Features are additional functionalities or components in the Windows operating system that users can choose to enable or disable based on their specific needs and preferences.


You can find information about Optional Windows Features on [Microsoft's Website for Optional Features](https://learn.microsoft.com/en-us/windows/client-management/client-tools/add-remove-hide-features?pivots=windows-11).

### Features to install
- ServicesForNFS-ClientOnly
- ClientForNFS-Infrastructure
- NFS-Administration

## Invoke Script

```powershell
nfsadmin client stop
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default' -Name 'AnonymousUID' -Type DWord -Value 0
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default' -Name 'AnonymousGID' -Type DWord -Value 0
nfsadmin client start
nfsadmin client localhost config fileaccess=755 SecFlavors=+sys -krb5 -krb5i

```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/feature.json)

