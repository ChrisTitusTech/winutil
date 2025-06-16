# 启动时启用 NumLock

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

切换计算机启动时 Num Lock 键的状态。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "NumLock on Startup",
  "Description": "Toggle the Num Lock key state when your computer starts.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a102_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Customize-Preferences/NumLock"
}
```

</details>

## 函数：Invoke-WinUtilNumLock

```powershell
function Invoke-WinUtilNumLock {
    <#
    .SYNOPSIS
        在启动时禁用/启用 NumLock
    .PARAMETER Enabled
        指示是否在启动时启用或禁用 Numlock
    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "正在启用启动时 Numlock"
            $value = 2
        } else {
            Write-Host "正在禁用启动时 Numlock"
            $value = 0
        }
        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
        $HKUPath = "HKU:\.Default\Control Panel\Keyboard"
        $HKCUPath = "HKCU:\Control Panel\Keyboard"
        Set-ItemProperty -Path $HKUPath -Name InitialKeyboardIndicators -Value $value
        Set-ItemProperty -Path $HKCUPath -Name InitialKeyboardIndicators -Value $value
    }
    Catch [System.Security.SecurityException] {
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
