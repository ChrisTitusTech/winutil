# 通过右键单击启用结束任务

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

启用在任务栏中右键单击程序时结束任务的选项

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

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
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Essential-Tweaks/EndTaskOnTaskbar"
}
```

</details>

## 调用脚本

```powershell
$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
      $name = "TaskbarEndTask"
      $value = 1

      # 确保注册表项存在
      if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
      }

      # 设置属性，如果不存在则创建它
      New-ItemProperty -Path $path -Name $name -PropertyType DWord -Value $value -Force | Out-Null

```
## 撤销脚本

```powershell
$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
      $name = "TaskbarEndTask"
      $value = 0

      # 确保注册表项存在
      if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
      }

      # 设置属性，如果不存在则创建它
      New-ItemProperty -Path $path -Name $name -PropertyType DWord -Value $value -Force | Out-Null

```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
