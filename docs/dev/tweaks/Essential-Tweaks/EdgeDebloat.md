# Edge 精简

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

禁用 Edge 中的各种遥测选项、弹出窗口和其他烦人的功能。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Debloat Edge",
  "Description": "Disables various telemetry options, popups, and other annoyances in Edge.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a016_",
  "registry": [
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\EdgeUpdate",
      "Name": "CreateDesktopShortcutDefault",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "EdgeEnhanceImagesEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "PersonalizationReportingEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "ShowRecommendationsEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "HideFirstRunExperience",
      "Type": "DWord",
      "Value": "1",
      "OriginalValue": "0"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "UserFeedbackAllowed",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "ConfigureDoNotTrack",
      "Type": "DWord",
      "Value": "1",
      "OriginalValue": "0"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "AlternateErrorPagesEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "EdgeCollectionsEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "EdgeFollowEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "EdgeShoppingAssistantEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "MicrosoftEdgeInsiderPromotionEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "PersonalizationReportingEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "ShowMicrosoftRewards",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "WebWidgetAllowed",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "DiagnosticData",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "EdgeAssetDeliveryServiceEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "EdgeCollectionsEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "CryptoWalletEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "ConfigureDoNotTrack",
      "Type": "DWord",
      "Value": "1",
      "OriginalValue": "0"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "WalletDonationEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    }
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Essential-Tweaks/EdgeDebloat"
}
```

</details>

## 注册表更改
应用程序和系统组件存储和检索配置数据以修改 Windows 设置，因此我们可以使用注册表在一个位置更改许多设置。


您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/windows/win32/sysinfo/registry)上找到有关注册表的信息。

### 注册表项：CreateDesktopShortcutDefault

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：EdgeEnhanceImagesEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：PersonalizationReportingEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：ShowRecommendationsEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：HideFirstRunExperience

**类型：** DWord

**原始值：** 0

**新值：** 1

### 注册表项：UserFeedbackAllowed

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：ConfigureDoNotTrack

**类型：** DWord

**原始值：** 0

**新值：** 1

### 注册表项：AlternateErrorPagesEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：EdgeCollectionsEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：EdgeFollowEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：EdgeShoppingAssistantEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：MicrosoftEdgeInsiderPromotionEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：PersonalizationReportingEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：ShowMicrosoftRewards

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：WebWidgetAllowed

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：DiagnosticData

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：EdgeAssetDeliveryServiceEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：EdgeCollectionsEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：CryptoWalletEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：ConfigureDoNotTrack

**类型：** DWord

**原始值：** 0

**新值：** 1

### 注册表项：WalletDonationEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
