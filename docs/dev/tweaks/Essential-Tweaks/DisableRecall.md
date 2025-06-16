# 禁用 Microsoft Recall

最后更新时间：2024-10-24


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

禁用自 24H2 版本以来内置于 Windows 中的 MS Recall 功能。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
"WPFTweaksRecallOff": {
    "Content": "Disable Recall",
    "Description": "Turn Recall off",
    "category": "Essential Tweaks",
    "panel": "1",
    "Order": "a011_",
    "registry": [
      {

        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\WindowsAI",
        "Name": "DisableAIDataAnalysis",
        "Type": "DWord",
        "Value": "1",
        "OriginalValue": "0"
      }
    ],
    "InvokeScript": [
      "
      Write-Host \"禁用 Recall\"
      DISM /Online /Disable-Feature /FeatureName:Recall
      "
    ],
    "UndoScript": [
      "
      Write-Host \"启用 Recall\"
      DISM /Online /Enable-Feature /FeatureName:Recall
      "
    ],
    "link": "https://christitustech.github.io/winutil/dev/tweaks/Essential-Tweaks/DisableRecall"
  },
```

</details>

## 调用脚本

```powershell

      Write-Host "禁用 Recall"
      DISM /Online /Disable-Feature /FeatureName:Recall


```
## 撤销脚本

```powershell

      Write-Host "启用 Recall"
      DISM /Online /Enable-Feature /FeatureName:Recall


```
## 注册表更改
应用程序和系统组件存储和检索配置数据以修改 Windows 设置，因此我们可以使用注册表在一个位置更改许多设置。


您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/windows/win32/sysinfo/registry)上找到有关注册表的信息。

### 注册表项：DisableAIDataAnalysis

**类型：** DWord

**原始值：** 0

**新值：** 1

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
