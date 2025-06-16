# 在注册表中禁用搜索框 Web 建议（资源管理器重新启动）

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

在使用 Windows 搜索时禁用 Web 建议。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Disable Search Box Web Suggestions in Registry(explorer restart)",
  "Description": "Disables web suggestions when searching using Windows Search.",
  "category": "Features",
  "panel": "1",
  "Order": "a016_",
  "feature": [],
  "InvokeScript": [
    "
      If (!(Test-Path 'HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer')) {
            New-Item -Path 'HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer' -Force | Out-Null
      }
      New-ItemProperty -Path 'HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Explorer' -Name 'DisableSearchBoxSuggestions' -Type DWord -Value 1 -Force
      Stop-Process -name explorer -force
      "
  ],
  "link": "https://christitustech.github.io/winutil/dev/features/Features/DisableSearchSuggestions"
}
```

</details>

## 调用脚本

```powershell

      If (!(Test-Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer')) {
            New-Item -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Force | Out-Null
      }
      New-ItemProperty -Path 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -Type DWord -Value 1 -Force
      Stop-Process -name explorer -force


```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)
