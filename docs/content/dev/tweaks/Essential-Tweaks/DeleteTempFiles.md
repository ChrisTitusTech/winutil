# Delete Temporary Files

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Erases TEMP Folders

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Delete Temporary Files",
  "Description": "Erases TEMP Folders",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a002_",
  "InvokeScript": [
    "Get-ChildItem -Path \"C:\\Windows\\Temp\" *.* -Recurse | Remove-Item -Force -Recurse
    Get-ChildItem -Path $env:TEMP *.* -Recurse | Remove-Item -Force -Recurse"
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/DeleteTempFiles"
}
```

</details>

## Invoke Script

```powershell
Get-ChildItem -Path "C:\Windows\Temp" *.* -Recurse | Remove-Item -Force -Recurse
    Get-ChildItem -Path $env:TEMP *.* -Recurse | Remove-Item -Force -Recurse

```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

