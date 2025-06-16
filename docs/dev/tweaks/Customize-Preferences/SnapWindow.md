# 贴靠窗口

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

如果启用，您可以通过拖动窗口来对齐窗口。| 需要重新登录

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Snap Window",
  "Description": "If enabled you can align windows by dragging them. | Relogin Required",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a104_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Customize-Preferences/SnapWindow"
}
```

</details>

## 函数：Invoke-WinUtilSnapWindow

```powershell
function Invoke-WinUtilSnapWindow {
    <#
    .SYNOPSIS
        在启动时禁用/启用贴靠窗口
    .PARAMETER Enabled
        指示是否在启动时启用或禁用贴靠窗口
    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "正在启用启动时贴靠窗口 | 需要重新登录"
            $value = 1
        } else {
            Write-Host "正在禁用启动时贴靠窗口 | 需要重新登录"
            $value = 0
        }
        $Path = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $Path -Name WindowArrangementActive -Value $value
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
