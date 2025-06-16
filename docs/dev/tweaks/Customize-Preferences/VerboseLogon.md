# 登录期间的详细消息

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

在登录过程中显示详细消息，以便进行故障排除和诊断。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Verbose Messages During Logon",
  "Description": "Show detailed messages during the login process for troubleshooting and diagnostics.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a103_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Customize-Preferences/VerboseLogon"
}
```

</details>

## 函数：Invoke-WinUtilVerboseLogon

```powershell
function Invoke-WinUtilVerboseLogon {
    <#
    .SYNOPSIS
        禁用/启用详细登录消息
    .PARAMETER Enabled
        指示是启用还是禁用详细登录消息
    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "正在启用详细登录消息"
            $value = 1
        } else {
            Write-Host "正在禁用详细登录消息"
            $value = 0
        }
        $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Set-ItemProperty -Path $Path -Name VerboseStatus -Value $value
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
