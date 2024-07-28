# Disable Storage Sense


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a bit part of the dev-docs stays up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


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
  ]
}
```
</details>



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

