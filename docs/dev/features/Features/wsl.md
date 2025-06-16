# 适用于 Linux 的 Windows 子系统

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

适用于 Linux 的 Windows 子系统是 Windows 的一项可选功能，允许 Linux 程序在 Windows 上本机运行，而无需单独的虚拟机或双启动。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Windows Subsystem for Linux",
  "Description": "Windows Subsystem for Linux is an optional feature of Windows that allows Linux programs to run natively on Windows without the need for a separate virtual machine or dual booting.",
  "category": "Features",
  "panel": "1",
  "Order": "a020_",
  "feature": [
    "VirtualMachinePlatform",
    "Microsoft-Windows-Subsystem-Linux"
  ],
  "InvokeScript": [],
  "link": "https://christitustech.github.io/winutil/dev/features/Features/wsl"
}
```

</details>

## 功能


可选 Windows 功能是 Windows 操作系统中的附加功能或组件，用户可以根据自己的特定需求和偏好选择启用或禁用这些功能或组件。


您可以在 [Microsoft 可选功能网站](https://learn.microsoft.com/zh-cn/windows/client-management/client-tools/add-remove-hide-features?pivots=windows-11)上找到有关可选 Windows 功能的信息。

### 要安装的功能
- VirtualMachinePlatform
- Microsoft-Windows-Subsystem-Linux


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)
