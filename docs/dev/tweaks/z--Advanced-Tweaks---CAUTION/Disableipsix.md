# 禁用 IPv6

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

禁用 IPv6。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Disable IPv6",
  "Description": "Disables IPv6.",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a023_",
  "registry": [
    {
      "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip6\\Parameters",
      "Name": "DisabledComponents",
      "Value": "255",
      "OriginalValue": "0",
      "Type": "DWord"
    }
  ],
  "InvokeScript": [
    "Disable-NetAdapterBinding -Name \"*\" -ComponentID ms_tcpip6"
  ],
  "UndoScript": [
    "Enable-NetAdapterBinding -Name \"*\" -ComponentID ms_tcpip6"
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/Disableipsix"
}
```

</details>

## 调用脚本

```powershell
Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6

```
## 撤销脚本

```powershell
Enable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6

```
## 注册表更改
应用程序和系统组件存储和检索配置数据以修改 Windows 设置，因此我们可以使用注册表在一个位置更改许多设置。


您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/windows/win32/sysinfo/registry)上找到有关注册表的信息。

### 注册表项：DisabledComponents

**类型：** DWord

**原始值：** 0

**新值：** 255



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
