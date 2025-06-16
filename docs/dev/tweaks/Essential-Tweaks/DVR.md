# 禁用 GameDVR

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

GameDVR 是一款 Windows 应用，是一些应用商店游戏的依赖项。我从未遇到过喜欢它的人，但它是为 XBOX 用户准备的。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Disable GameDVR",
  "Description": "GameDVR is a Windows App that is a dependency for some Store Games. I've never met someone that likes it, but it's there for the XBOX crowd.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a005_",
  "registry": [
    {
      "Path": "HKCU:\\System\\GameConfigStore",
      "Name": "GameDVR_FSEBehavior",
      "Value": "2",
      "OriginalValue": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\System\\GameConfigStore",
      "Name": "GameDVR_Enabled",
      "Value": "0",
      "OriginalValue": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\System\\GameConfigStore",
      "Name": "GameDVR_HonorUserFSEBehaviorMode",
      "Value": "1",
      "OriginalValue": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\System\\GameConfigStore",
      "Name": "GameDVR_EFSEFeatureFlags",
      "Value": "0",
      "OriginalValue": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\GameDVR",
      "Name": "AllowGameDVR",
      "Value": "0",
      "OriginalValue": "1",
      "Type": "DWord"
    }
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Essential-Tweaks/DVR"
}
```

</details>

## 注册表更改
应用程序和系统组件存储和检索配置数据以修改 Windows 设置，因此我们可以使用注册表在一个位置更改许多设置。


您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/windows/win32/sysinfo/registry)上找到有关注册表的信息。

### 注册表项：GameDVR_FSEBehavior

**类型：** DWord

**原始值：** 1

**新值：** 2

### 注册表项：GameDVR_Enabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：GameDVR_HonorUserFSEBehaviorMode

**类型：** DWord

**原始值：** 0

**新值：** 1

### 注册表项：GameDVR_EFSEFeatureFlags

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：AllowGameDVR

**类型：** DWord

**原始值：** 1

**新值：** 0



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
