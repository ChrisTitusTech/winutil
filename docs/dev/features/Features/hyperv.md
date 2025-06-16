# HyperV 虚拟化

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

Hyper-V 是 Microsoft 开发的硬件虚拟化产品，允许用户创建和管理虚拟机。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "HyperV Virtualization",
  "Description": "Hyper-V is a hardware virtualization product developed by Microsoft that allows users to create and manage virtual machines.",
  "category": "Features",
  "panel": "1",
  "Order": "a011_",
  "feature": [
    "HypervisorPlatform",
    "Microsoft-Hyper-V-All",
    "Microsoft-Hyper-V",
    "Microsoft-Hyper-V-Tools-All",
    "Microsoft-Hyper-V-Management-PowerShell",
    "Microsoft-Hyper-V-Hypervisor",
    "Microsoft-Hyper-V-Services",
    "Microsoft-Hyper-V-Management-Clients"
  ],
  "InvokeScript": [
    "Start-Process -FilePath cmd.exe -ArgumentList '/c bcdedit /set hypervisorschedulertype classic' -Wait"
  ],
  "link": "https://christitustech.github.io/winutil/dev/features/Features/hyperv"
}
```

</details>

## 功能


可选 Windows 功能是 Windows 操作系统中的附加功能或组件，用户可以根据自己的特定需求和偏好选择启用或禁用这些功能或组件。


您可以在 [Microsoft 可选功能网站](https://learn.microsoft.com/zh-cn/windows/client-management/client-tools/add-remove-hide-features?pivots=windows-11)上找到有关可选 Windows 功能的信息。

### 要安装的功能
- HypervisorPlatform
- Microsoft-Hyper-V-All
- Microsoft-Hyper-V
- Microsoft-Hyper-V-Tools-All
- Microsoft-Hyper-V-Management-PowerShell
- Microsoft-Hyper-V-Hypervisor
- Microsoft-Hyper-V-Services
- Microsoft-Hyper-V-Management-Clients

## 调用脚本

```powershell
Start-Process -FilePath cmd.exe -ArgumentList '/c bcdedit /set hypervisorschedulertype classic' -Wait

```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)
