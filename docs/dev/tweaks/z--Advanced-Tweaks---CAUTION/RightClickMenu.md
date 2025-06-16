# 设置经典右键菜单

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

很棒的 Windows 11 调整，可在资源管理器中右键单击项目时恢复良好的上下文菜单。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Set Classic Right-Click Menu ",
  "Description": "Great Windows 11 tweak to bring back good context menus when right clicking things in explorer.",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a027_",
  "InvokeScript": [
    "
      New-Item -Path \"HKCU:\\Software\\Classes\\CLSID\\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\" -Name \"InprocServer32\" -force -value \"\"
      Write-Host Restarting explorer.exe ...
      $process = Get-Process -Name \"explorer\"
      Stop-Process -InputObject $process
      "
  ],
  "UndoScript": [
    "
      Remove-Item -Path \"HKCU:\\Software\\Classes\\CLSID\\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\" -Recurse -Confirm:$false -Force
      # Restarting Explorer in the Undo Script might not be necessary, as the Registry change without restarting Explorer does work, but just to make sure.
      Write-Host Restarting explorer.exe ...
      $process = Get-Process -Name \"explorer\"
      Stop-Process -InputObject $process
      "
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/RightClickMenu"
}
```

</details>

## 调用脚本

```powershell

      New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Name "InprocServer32" -force -value ""
      Write-Host 正在重新启动 explorer.exe ...
      $process = Get-Process -Name "explorer"
      Stop-Process -InputObject $process


```
## 撤销脚本

```powershell

      Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Confirm:$false -Force
      # 撤销脚本中的重新启动资源管理器可能不是必需的，因为在不重新启动资源管理器的情况下注册表更改确实有效，但这只是为了确保。
      Write-Host 正在重新启动 explorer.exe ...
      $process = Get-Process -Name "explorer"
      Stop-Process -InputObject $process


```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
