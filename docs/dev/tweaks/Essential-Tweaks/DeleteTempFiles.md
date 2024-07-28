# Delete Temporary Files


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a bit part of the dev-docs stays up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Erases TEMP Folders

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Delete Temporary Files",
    "Description":  "Erases TEMP Folders",
    "category":  "Essential Tweaks",
    "panel":  "1",
    "Order":  "a002_",
    "InvokeScript":  [
                         "Get-ChildItem -Path \"C:\\Windows\\Temp\" *.* -Recurse | Remove-Item -Force -Recurse\r\n    Get-ChildItem -Path $env:TEMP *.* -Recurse | Remove-Item -Force -Recurse"
                     ]
}
```
</details>

## Invoke Script

```json
Get-ChildItem -Path "C:\Windows\Temp" *.* -Recurse | Remove-Item -Force -Recurse
    Get-ChildItem -Path $env:TEMP *.* -Recurse | Remove-Item -Force -Recurse

```



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

