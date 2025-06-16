# 将休眠设置为默认值（适用于笔记本电脑）

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

大多数现代笔记本电脑都启用了连接待机功能，这会消耗电池电量，此设置将休眠设置为默认值，从而不会消耗电池电量。请参阅问题 https://github.com/ChrisTitusTech/winutil/issues/1399

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Set Hibernation as default (good for laptops)",
  "Description": "Most modern laptops have connected standby enabled which drains the battery, this sets hibernation as default which will not drain the battery. See issue https://github.com/ChrisTitusTech/winutil/issues/1399",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a014_",
  "registry": [
    {
      "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Power\\PowerSettings\\238C9FA8-0AAD-41ED-83F4-97BE242C8F20\\7bc4a2f9-d8fc-4469-b07b-33eb785aaca0",
      "OriginalValue": "1",
      "Name": "Attributes",
      "Value": "2",
      "Type": "DWord"
    },
    {
      "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Power\\PowerSettings\\abfc2519-3608-4c2a-94ea-171b0ed546ab\\94ac6d29-73ce-41a6-809f-6363ba21b47e",
      "OriginalValue": "0",
      "Name": "Attributes ",
      "Value": "2",
      "Type": "DWord"
    }
  ],
  "InvokeScript": [
    "
      Write-Host \"开启休眠\"
      Start-Process -FilePath powercfg -ArgumentList \"/hibernate on\" -NoNewWindow -Wait

      # Set hibernation as the default action
      Start-Process -FilePath powercfg -ArgumentList \"/change standby-timeout-ac 60\" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList \"/change standby-timeout-dc 60\" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList \"/change monitor-timeout-ac 10\" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList \"/change monitor-timeout-dc 1\" -NoNewWindow -Wait
      "
  ],
  "UndoScript": [
    "
      Write-Host \"关闭休眠\"
      Start-Process -FilePath powercfg -ArgumentList \"/hibernate off\" -NoNewWindow -Wait

      # Set standby to detault values
      Start-Process -FilePath powercfg -ArgumentList \"/change standby-timeout-ac 15\" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList \"/change standby-timeout-dc 15\" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList \"/change monitor-timeout-ac 15\" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList \"/change monitor-timeout-dc 15\" -NoNewWindow -Wait
      "
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Essential-Tweaks/LaptopHibernation"
}
```

</details>

## 调用脚本

```powershell

      Write-Host "开启休眠"
      Start-Process -FilePath powercfg -ArgumentList "/hibernate on" -NoNewWindow -Wait

      # 将休眠设置为默认操作
      Start-Process -FilePath powercfg -ArgumentList "/change standby-timeout-ac 60" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList "/change standby-timeout-dc 60" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList "/change monitor-timeout-ac 10" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList "/change monitor-timeout-dc 1" -NoNewWindow -Wait


```
## 撤销脚本

```powershell

      Write-Host "关闭休眠"
      Start-Process -FilePath powercfg -ArgumentList "/hibernate off" -NoNewWindow -Wait

      # 将待机设置为默认值
      Start-Process -FilePath powercfg -ArgumentList "/change standby-timeout-ac 15" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList "/change standby-timeout-dc 15" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList "/change monitor-timeout-ac 15" -NoNewWindow -Wait
      Start-Process -FilePath powercfg -ArgumentList "/change monitor-timeout-dc 15" -NoNewWindow -Wait


```
## 注册表更改
应用程序和系统组件存储和检索配置数据以修改 Windows 设置，因此我们可以使用注册表在一个位置更改许多设置。


您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/windows/win32/sysinfo/registry)上找到有关注册表的信息。

### 注册表项：Attributes

**类型：** DWord

**原始值：** 1

**新值：** 2

### 注册表项：Attributes

**类型：** DWord

**原始值：** 0

**新值：** 2



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
