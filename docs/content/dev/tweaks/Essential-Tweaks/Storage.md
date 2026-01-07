# Disable Storage Sense

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Storage Sense deletes temp files automatically.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Disable Storage Sense",
  "Description": "Storage Sense deletes temp files automatically.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a005_",
  "InvokeScript": [
    "Set-ItemProperty -Path \"HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\StorageSense\\Parameters\\StoragePolicy\" -Name \"01\" -Value 0 -Type Dword -Force"
  ],
  "UndoScript": [
    "Set-ItemProperty -Path \"HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\StorageSense\\Parameters\\StoragePolicy\" -Name \"01\" -Value 1 -Type Dword -Force"
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/Storage"
}
```

</details>

## Invoke Script

```powershell
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type Dword -Force

```
## Undo Script

```powershell
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 1 -Type Dword -Force

```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

