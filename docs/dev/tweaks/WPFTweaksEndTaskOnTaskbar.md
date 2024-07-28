# Enable End Task With Right Click


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a bit part of the dev-docs stays up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Enables option to end task when right clicking a program in the taskbar

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Enable End Task With Right Click",
  "Description": "Enables option to end task when right clicking a program in the taskbar",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a006_",
  "InvokeScript": [
    "$path = \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\TaskbarDeveloperSettings\"\r\n      $name = \"TaskbarEndTask\"\r\n      $value = 1\r\n\r\n      # Ensure the registry key exists\r\n      if (-not (Test-Path $path)) {\r\n        New-Item -Path $path -Force | Out-Null\r\n      }\r\n\r\n      # Set the property, creating it if it doesn't exist\r\n      New-ItemProperty -Path $path -Name $name -PropertyType DWord -Value $value -Force | Out-Null"
  ],
  "UndoScript": [
    "$path = \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\TaskbarDeveloperSettings\"\r\n      $name = \"TaskbarEndTask\"\r\n      $value = 0\r\n\r\n      # Ensure the registry key exists\r\n      if (-not (Test-Path $path)) {\r\n        New-Item -Path $path -Force | Out-Null\r\n      }\r\n\r\n      # Set the property, creating it if it doesn't exist\r\n      New-ItemProperty -Path $path -Name $name -PropertyType DWord -Value $value -Force | Out-Null"
  ]
}
```
</details>



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

