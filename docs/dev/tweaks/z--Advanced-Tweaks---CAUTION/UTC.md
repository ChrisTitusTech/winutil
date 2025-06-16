# 将时间设置为 UTC（双启动）

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

对于双启动计算机至关重要。修复与 Linux 系统的时间同步问题。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Set Time to UTC (Dual Boot)",
  "Description": "Essential for computers that are dual booting. Fixes the time sync with Linux Systems.",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a027_",
  "registry": [
    {
      "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\TimeZoneInformation",
      "Name": "RealTimeIsUniversal",
      "Type": "DWord",
      "Value": "1",
      "OriginalValue": "0"
    }
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/UTC"
}
```

</details>

## 注册表更改
应用程序和系统组件存储和检索配置数据以修改 Windows 设置，因此我们可以使用注册表在一个位置更改许多设置。


您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/windows/win32/sysinfo/registry)上找到有关注册表的信息。

### 注册表项：RealTimeIsUniversal

**类型：** DWord

**原始值：** 0

**新值：** 1



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
