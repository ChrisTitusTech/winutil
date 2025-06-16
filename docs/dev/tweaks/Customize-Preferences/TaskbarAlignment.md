# 居中任务栏项目

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

[Windows 11] 如果启用，则任务栏项目将显示在中间，否则任务栏项目将显示在左侧。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Center Taskbar Items",
  "Description": "[Windows 11] If Enabled then the Taskbar Items will be shown on the Center, otherwise the Taskbar Items will be shown on the Left.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a204_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Customize-Preferences/TaskbarAlignment"
}
```

</details>

## 函数：Invoke-WinUtilTaskbarAlignment

```powershell
function Invoke-WinUtilTaskbarAlignment {
    <#

    .SYNOPSIS
        在居中和左对齐任务栏之间切换

    .PARAMETER Enabled
        指示是将任务栏对齐方式设置为居中还是左对齐

    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "正在将任务栏对齐方式设置为居中"
            $value = 1
        } else {
            Write-Host "正在将任务栏对齐方式设置为左对齐"
            $value = 0
        }
        $Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $Path -Name "TaskbarAl" -Value $value
    } catch [System.Security.SecurityException] {
        Write-Warning "由于安全异常，无法将 $Path\$Name 设置为 $value"
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    } catch {
        Write-Warning "由于未处理的异常，无法设置 $Name"
        Write-Warning $psitem.Exception.StackTrace
    }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
