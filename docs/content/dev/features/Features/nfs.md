---
title: "NFS - Network File System"
description: ""
---

```json {filename="config/feature.json",linenos=inline,linenostart=53}
  "WPFFeaturenfs": {
    "Content": "NFS - Network File System",
    "Description": "Network File System (NFS) is a mechanism for storing files on a network.",
    "category": "Features",
    "panel": "1",
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
```
