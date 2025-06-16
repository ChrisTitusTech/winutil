# 详细蓝屏 (BSoD)

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

如果启用，您将看到包含更多信息的详细蓝屏 (BSOD)。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Detailed BSoD",
  "Description": "If Enabled then you will see a detailed Blue Screen of Death (BSOD) with more information.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a205_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Customize-Preferences/DetailedBSoD"
}
```

</details>

## 函数：Invoke-WinUtilDetailedBSoD

```powershell
Function Invoke-WinUtilDetailedBSoD {
    <#

    .SYNOPSIS
        启用/禁用详细蓝屏
        (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Name 'DisplayParameters').DisplayParameters


    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "正在启用详细蓝屏"
            $value = 1
        } else {
            Write-Host "正在禁用详细蓝屏"
            $value =0
        }

        $Path = "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl"
        Set-ItemProperty -Path $Path -Name DisplayParameters -Value $value
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
