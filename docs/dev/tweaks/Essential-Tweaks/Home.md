# 禁用家庭组

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

禁用家庭组 - 家庭组是一项受密码保护的家庭网络服务，可让您与当前正在运行并连接到网络的其他电脑共享您的内容。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Disable Homegroup",
  "Description": "Disables HomeGroup - HomeGroup is a password-protected home networking service that lets you share your stuff with other PCs that are currently running and connected to your network.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a005_",
  "service": [
    {
      "Name": "HomeGroupListener",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "HomeGroupProvider",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    }
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Essential-Tweaks/Home"
}
```

</details>

## 服务更改

Windows 服务是用于系统功能或应用程序的后台进程。将某些服务设置为手动可以通过仅在需要时启动它们来优化性能。

您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_service) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/dotnet/framework/windows-services/introduction-to-windows-service-applications)上找到有关服务的信息。

### 服务名称：HomeGroupListener

**启动类型：** 手动

**原始类型：** 自动

### 服务名称：HomeGroupProvider

**启动类型：** 手动

**原始类型：** 自动



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
