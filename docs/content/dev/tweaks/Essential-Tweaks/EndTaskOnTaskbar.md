# Enable End Task With Right Click

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
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
    "$path = \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\TaskbarDeveloperSettings\"
      $name = \"TaskbarEndTask\"
      $value = 1

      # Ensure the registry key exists
      if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
      }

      # Set the property, creating it if it doesn't exist
      New-ItemProperty -Path $path -Name $name -PropertyType DWord -Value $value -Force | Out-Null"
  ],
  "UndoScript": [
    "$path = \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\TaskbarDeveloperSettings\"
      $name = \"TaskbarEndTask\"
      $value = 0

      # Ensure the registry key exists
      if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
      }

      # Set the property, creating it if it doesn't exist
      New-ItemProperty -Path $path -Name $name -PropertyType DWord -Value $value -Force | Out-Null"
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/EndTaskOnTaskbar"
}
```

</details>

## Invoke Script

```powershell
$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
      $name = "TaskbarEndTask"
      $value = 1

      # Ensure the registry key exists
      if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
      }

      # Set the property, creating it if it doesn't exist
      New-ItemProperty -Path $path -Name $name -PropertyType DWord -Value $value -Force | Out-Null

```
## Undo Script

```powershell
$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
      $name = "TaskbarEndTask"
      $value = 0

      # Ensure the registry key exists
      if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
      }

      # Set the property, creating it if it doesn't exist
      New-ItemProperty -Path $path -Name $name -PropertyType DWord -Value $value -Force | Out-Null

```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

