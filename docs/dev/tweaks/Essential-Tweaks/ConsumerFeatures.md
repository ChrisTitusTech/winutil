# 禁用消费者功能

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

Windows 10 不会自动为已登录用户从 Windows 应用商店安装任何游戏、第三方应用或应用程序链接。某些默认应用将无法访问（例如“手机连接”）。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Disable ConsumerFeatures",
  "Description": "Windows 10 will not automatically install any games, third-party apps, or application links from the Windows Store for the signed-in user. Some default Apps will be inaccessible (eg. Phone Link)",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a003_",
  "registry": [
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent",
      "OriginalValue": "0",
      "Name": "DisableWindowsConsumerFeatures",
      "Value": "1",
      "Type": "DWord"
    }
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Essential-Tweaks/ConsumerFeatures"
}
```

</details>

## 注册表更改
应用程序和系统组件存储和检索配置数据以修改 Windows 设置，因此我们可以使用注册表在一个位置更改许多设置。


您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/windows/win32/sysinfo/registry)上找到有关注册表的信息。

### 注册表项：DisableWindowsConsumerFeatures

**类型：** DWord

**原始值：** 0

**新值：** 1



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
