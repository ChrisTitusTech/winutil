# NFS - Network File System


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a bit part of the dev-docs stays up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


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
  ]
}
```
</details>



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)

