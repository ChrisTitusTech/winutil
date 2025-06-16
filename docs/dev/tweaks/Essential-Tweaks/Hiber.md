# 禁用休眠

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

休眠功能主要用于笔记本电脑，它会在关闭电脑前保存内存中的内容。它实际上不应该被使用，但有些人很懒惰并依赖它。不要像鲍勃那样。鲍勃喜欢休眠。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Disable Hibernation",
  "Description": "Hibernation is really meant for laptops as it saves what's in memory before turning the pc off. It really should never be used, but some people are lazy and rely on it. Don't be like Bob. Bob likes hibernation.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a005_",
  "registry": [
    {
      "Path": "HKLM:\\System\\CurrentControlSet\\Control\\Session Manager\\Power",
      "Name": "HibernateEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FlyoutMenuSettings",
      "Name": "ShowHibernateOption",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    }
  ],
  "InvokeScript": [
    "powercfg.exe /hibernate off"
  ],
  "UndoScript": [
    "powercfg.exe /hibernate on"
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Essential-Tweaks/Hiber"
}
```

</details>

## 调用脚本

```powershell
powercfg.exe /hibernate off

```
## 撤销脚本

```powershell
powercfg.exe /hibernate on

```
## 注册表更改
应用程序和系统组件存储和检索配置数据以修改 Windows 设置，因此我们可以使用注册表在一个位置更改许多设置。


您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/windows/win32/sysinfo/registry)上找到有关注册表的信息。

### 注册表项：HibernateEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：ShowHibernateOption

**类型：** DWord

**原始值：** 1

**新值：** 0



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
