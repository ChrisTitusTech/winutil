# Remove Home and Gallery from explorer

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Removes the Home and Gallery from explorer and sets This PC as default

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Remove Home and Gallery from explorer",
    "Description":  "Removes the Home and Gallery from explorer and sets This PC as default",
    "link":  "https://christitustech.github.io/winutil/dev/tweaks/Shortcuts/Shortcut",
    "category":  "z__Advanced Tweaks - CAUTION",
    "panel":  "1",
    "Order":  "a029_",
    "InvokeScript":  [
                         "\r\n      REG DELETE \"HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Desktop\\NameSpace\\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}\" /f\r\n      REG DELETE \"HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Desktop\\NameSpace\\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}\" /f\r\n      REG ADD \"HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\" /f /v \"LaunchTo\" /t REG_DWORD /d \"1\"\r\n      "
                     ],
    "UndoScript":  [
                       "\r\n      REG ADD \"HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Desktop\\NameSpace\\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}\" /f /ve /t REG_SZ /d \"{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}\"\r\n      REG ADD \"HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Desktop\\NameSpace\\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}\" /f /ve /t REG_SZ /d \"CLSID_MSGraphHomeFolder\"\r\n      REG DELETE \"HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\" /f /v \"LaunchTo\"\r\n      "
                   ]
}
```
</details>

## Invoke Script

```powershell

      REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /f
      REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" /f
      REG ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v "LaunchTo" /t REG_DWORD /d "1"
      

```
## Undo Script

```powershell

      REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" /f /ve /t REG_SZ /d "{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
      REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" /f /ve /t REG_SZ /d "CLSID_MSGraphHomeFolder"
      REG DELETE "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /f /v "LaunchTo"
      

```
<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

