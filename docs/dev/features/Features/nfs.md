# NFS - Network File System

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Network File System (NFS) is a mechanism for storing files on a network.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "NFS - Network File System",
    "Description":  "Network File System (NFS) is a mechanism for storing files on a network.",
    "link":  "https://christitustech.github.io/winutil/dev/features/Legacy-Windows-Panels/user",
    "category":  "Features",
    "panel":  "1",
    "Order":  "a014_",
    "feature":  [
                    "ServicesForNFS-ClientOnly",
                    "ClientForNFS-Infrastructure",
                    "NFS-Administration"
                ],
    "InvokeScript":  [
                         "nfsadmin client stop",
                         "Set-ItemProperty -Path \u0027HKLM:\\SOFTWARE\\Microsoft\\ClientForNFS\\CurrentVersion\\Default\u0027 -Name \u0027AnonymousUID\u0027 -Type DWord -Value 0",
                         "Set-ItemProperty -Path \u0027HKLM:\\SOFTWARE\\Microsoft\\ClientForNFS\\CurrentVersion\\Default\u0027 -Name \u0027AnonymousGID\u0027 -Type DWord -Value 0",
                         "nfsadmin client start",
                         "nfsadmin client localhost config fileaccess=755 SecFlavors=+sys -krb5 -krb5i"
                     ]
}
```
</details>

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

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)

