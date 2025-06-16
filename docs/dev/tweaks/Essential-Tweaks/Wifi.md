# 禁用 Wi-Fi 感知

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

Wi-Fi 感知是一项间谍服务，它会将附近所有扫描到的 Wi-Fi 网络和您当前的地理位置发送回总部。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Disable Wifi-Sense",
  "Description": "Wifi Sense is a spying service that phones home all nearby scanned wifi networks and your current geo location.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a005_",
  "registry": [
    {
      "Path": "HKLM:\\Software\\Microsoft\\PolicyManager\\default\\WiFi\\AllowWiFiHotSpotReporting",
      "Name": "Value",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\Software\\Microsoft\\PolicyManager\\default\\WiFi\\AllowAutoConnectToWiFiSenseHotspots",
      "Name": "Value",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    }
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Essential-Tweaks/Wifi"
}
```

</details>

## 注册表更改
应用程序和系统组件存储和检索配置数据以修改 Windows 设置，因此我们可以使用注册表在一个位置更改许多设置。


您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/windows/win32/sysinfo/registry)上找到有关注册表的信息。

### 注册表项：Value

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：Value

**类型：** DWord

**原始值：** 1

**新值：** 0



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
