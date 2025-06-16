# 禁用位置跟踪

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

禁用位置跟踪……显而易见！

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Disable Location Tracking",
  "Description": "Disables Location Tracking...DUH!",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a005_",
  "registry": [
    {
      "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\location",
      "Name": "Value",
      "Type": "String",
      "Value": "Deny",
      "OriginalValue": "Allow"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Sensor\\Overrides\\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}",
      "Name": "SensorPermissionState",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\lfsvc\\Service\\Configuration",
      "Name": "Status",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SYSTEM\\Maps",
      "Name": "AutoUpdateEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    }
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Essential-Tweaks/Loc"
}
```

</details>

## 注册表更改
应用程序和系统组件存储和检索配置数据以修改 Windows 设置，因此我们可以使用注册表在一个位置更改许多设置。


您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/windows/win32/sysinfo/registry)上找到有关注册表的信息。

### 注册表项：Value

**类型：** String

**原始值：** Allow

**新值：** Deny

### 注册表项：SensorPermissionState

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：Status

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：AutoUpdateEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
