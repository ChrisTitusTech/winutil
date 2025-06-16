# 禁用旧版 F8 启动恢复

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

禁用高级启动选项屏幕，该屏幕允许您以高级故障排除模式启动 Windows。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Disable Legacy F8 Boot Recovery",
  "Description": "Disables Advanced Boot Options screen that lets you start Windows in advanced troubleshooting modes.",
  "category": "Features",
  "panel": "1",
  "Order": "a019_",
  "feature": [],
  "InvokeScript": [
    "
      If (!(Test-Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager\\LastKnownGood')) {
            New-Item -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager\\LastKnownGood' -Force | Out-Null
      }
      New-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager\\LastKnownGood' -Name 'Enabled' -Type DWord -Value 0 -Force
      Start-Process -FilePath cmd.exe -ArgumentList '/c bcdedit /Set {Current} BootMenuPolicy Standard' -Wait
      "
  ],
  "link": "https://christitustech.github.io/winutil/dev/features/Features/DisableLegacyRecovery"
}
```

</details>

## 调用脚本

```powershell

      If (!(Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager\LastKnownGood')) {
            New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager\LastKnownGood' -Force | Out-Null
      }
      New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager\LastKnownGood' -Name 'Enabled' -Type DWord -Value 0 -Force
      Start-Process -FilePath cmd.exe -ArgumentList '/c bcdedit /Set {Current} BootMenuPolicy Standard' -Wait


```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)
