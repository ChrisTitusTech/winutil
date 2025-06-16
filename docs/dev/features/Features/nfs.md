# NFS - 网络文件系统

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

网络文件系统 (NFS) 是一种在网络上存储文件的机制。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "NFS - Network File System",
  "Description": "Network File System (NFS) is a mechanism for storing files on a network.",
  "category": "Features",
  "panel": "1",
  "Order": "a014_",
  "feature": [
    "ServicesForNFS-ClientOnly",
    "ClientForNFS-Infrastructure",
    "NFS-Administration"
  ],
  "InvokeScript": [
    "nfsadmin client stop",
    "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\ClientForNFS\\CurrentVersion\\Default' -Name 'AnonymousUID' -Type DWord -Value 0",
    "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\ClientForNFS\\CurrentVersion\\Default' -Name 'AnonymousGID' -Type DWord -Value 0",
    "nfsadmin client start",
    "nfsadmin client localhost config fileaccess=755 SecFlavors=+sys -krb5 -krb5i"
  ],
  "link": "https://christitustech.github.io/winutil/dev/features/Features/nfs"
}
```

</details>

## 功能


可选 Windows 功能是 Windows 操作系统中的附加功能或组件，用户可以根据自己的特定需求和偏好选择启用或禁用这些功能或组件。


您可以在 [Microsoft 可选功能网站](https://learn.microsoft.com/zh-cn/windows/client-management/client-tools/add-remove-hide-features?pivots=windows-11)上找到有关可选 Windows 功能的信息。

### 要安装的功能
- ServicesForNFS-ClientOnly
- ClientForNFS-Infrastructure
- NFS-Administration

## 调用脚本

```powershell
nfsadmin client stop
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default' -Name 'AnonymousUID' -Type DWord -Value 0
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default' -Name 'AnonymousGID' -Type DWord -Value 0
nfsadmin client start
nfsadmin client localhost config fileaccess=755 SecFlavors=+sys -krb5 -krb5i

```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)
