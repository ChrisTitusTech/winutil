﻿# Run Disk Cleanup


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Runs Disk Cleanup on Drive C: and removes old Windows Updates.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Run Disk Cleanup",
    "Description":  "Runs Disk Cleanup on Drive C: and removes old Windows Updates.",
    "category":  "Essential Tweaks",
    "panel":  "1",
    "Order":  "a009_",
    "InvokeScript":  [
                         "\r\n      cleanmgr.exe /d C: /VERYLOWDISK\r\n      Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase\r\n      "
                     ]
}
```
</details>

## Invoke Script

```json

      cleanmgr.exe /d C: /VERYLOWDISK
      Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
      

```
<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
