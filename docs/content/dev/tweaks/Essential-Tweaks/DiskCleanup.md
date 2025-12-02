# Run Disk Cleanup

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Runs Disk Cleanup on Drive C: and removes old Windows Updates.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Run Disk Cleanup",
  "Description": "Runs Disk Cleanup on Drive C: and removes old Windows Updates.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a009_",
  "InvokeScript": [
    "
      cleanmgr.exe /d C: /VERYLOWDISK
      Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
      "
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/DiskCleanup"
}
```

</details>

## Invoke Script

```powershell

      cleanmgr.exe /d C: /VERYLOWDISK
      Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase


```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

