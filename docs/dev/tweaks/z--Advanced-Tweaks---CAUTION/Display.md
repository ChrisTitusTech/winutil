# 设置显示为性能

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

将系统首选项设置为性能。您也可以使用 sysdm.cpl 手动执行此操作。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Set Display for Performance",
  "Description": "Sets the system preferences to performance. You can do this manually with sysdm.cpl as well.",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a027_",
  "registry": [
    {
      "Path": "HKCU:\\Control Panel\\Desktop",
      "OriginalValue": "1",
      "Name": "DragFullWindows",
      "Value": "0",
      "Type": "String"
    },
    {
      "Path": "HKCU:\\Control Panel\\Desktop",
      "OriginalValue": "1",
      "Name": "MenuShowDelay",
      "Value": "200",
      "Type": "String"
    },
    {
      "Path": "HKCU:\\Control Panel\\Desktop\\WindowMetrics",
      "OriginalValue": "1",
      "Name": "MinAnimate",
      "Value": "0",
      "Type": "String"
    },
    {
      "Path": "HKCU:\\Control Panel\\Keyboard",
      "OriginalValue": "1",
      "Name": "KeyboardDelay",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "OriginalValue": "1",
      "Name": "ListviewAlphaSelect",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "OriginalValue": "1",
      "Name": "ListviewShadow",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "OriginalValue": "1",
      "Name": "TaskbarAnimations",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\VisualEffects",
      "OriginalValue": "1",
      "Name": "VisualFXSetting",
      "Value": "3",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\DWM",
      "OriginalValue": "1",
      "Name": "EnableAeroPeek",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "OriginalValue": "1",
      "Name": "TaskbarMn",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "OriginalValue": "1",
      "Name": "TaskbarDa",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "OriginalValue": "1",
      "Name": "ShowTaskViewButton",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Search",
      "OriginalValue": "1",
      "Name": "SearchboxTaskbarMode",
      "Value": "0",
      "Type": "DWord"
    }
  ],
  "InvokeScript": [
    "Set-ItemProperty -Path \"HKCU:\\Control Panel\\Desktop\" -Name \"UserPreferencesMask\" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))"
  ],
  "UndoScript": [
    "Remove-ItemProperty -Path \"HKCU:\\Control Panel\\Desktop\" -Name \"UserPreferencesMask\""
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/Display"
}
```

</details>

## 调用脚本

```powershell
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](144,18,3,128,16,0,0,0))

```
## 撤销脚本

```powershell
Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask"

```
## 注册表更改
应用程序和系统组件存储和检索配置数据以修改 Windows 设置，因此我们可以使用注册表在一个位置更改许多设置。


您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/windows/win32/sysinfo/registry)上找到有关注册表的信息。

### 注册表项：DragFullWindows

**类型：** String

**原始值：** 1

**新值：** 0

### 注册表项：MenuShowDelay

**类型：** String

**原始值：** 1

**新值：** 200

### 注册表项：MinAnimate

**类型：** String

**原始值：** 1

**新值：** 0

### 注册表项：KeyboardDelay

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：ListviewAlphaSelect

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：ListviewShadow

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：TaskbarAnimations

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：VisualFXSetting

**类型：** DWord

**原始值：** 1

**新值：** 3

### 注册表项：EnableAeroPeek

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：TaskbarMn

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：TaskbarDa

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：ShowTaskViewButton

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：SearchboxTaskbarMode

**类型：** DWord

**原始值：** 1

**新值：** 0



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
