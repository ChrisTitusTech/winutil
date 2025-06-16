# 鼠标加速

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

如果启用，则光标移动会受到物理鼠标移动速度的影响。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Mouse Acceleration",
  "Description": "If Enabled then Cursor movement is affected by the speed of your physical mouse movements.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a107_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Customize-Preferences/MouseAcceleration"
}
```

</details>

## 函数：Invoke-WinUtilMouseAcceleration

```powershell
Function Invoke-WinUtilMouseAcceleration {
    <#

    .SYNOPSIS
        启用/禁用鼠标加速

    .PARAMETER DarkMoveEnabled
        指示当前鼠标加速状态

    #>
    Param($MouseAccelerationEnabled)
    try {
        if ($MouseAccelerationEnabled -eq $false) {
            Write-Host "正在启用鼠标加速"
            $MouseSpeed = 1
            $MouseThreshold1 = 6
            $MouseThreshold2 = 10
        } else {
            Write-Host "正在禁用鼠标加速"
            $MouseSpeed = 0
            $MouseThreshold1 = 0
            $MouseThreshold2 = 0

        }

        $Path = "HKCU:\Control Panel\Mouse"
        Set-ItemProperty -Path $Path -Name MouseSpeed -Value $MouseSpeed
        Set-ItemProperty -Path $Path -Name MouseThreshold1 -Value $MouseThreshold1
        Set-ItemProperty -Path $Path -Name MouseThreshold2 -Value $MouseThreshold2
    } catch [System.Security.SecurityException] {
        Write-Warning "由于安全异常，无法将 $Path\$Name 设置为 $Value"
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
