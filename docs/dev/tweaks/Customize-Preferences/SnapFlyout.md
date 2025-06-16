# 贴靠辅助浮出控件

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

如果启用，则在将鼠标悬停在最大化按钮上时禁用贴靠预览。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Snap Assist Flyout",
  "Description": "If enabled then Snap preview is disabled when maximize button is hovered.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a105_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Customize-Preferences/SnapFlyout"
}
```

</details>

## 函数：Invoke-WinUtilSnapFlyout

```powershell
function Invoke-WinUtilSnapFlyout {
    <#
    .SYNOPSIS
        在启动时禁用/启用贴靠辅助浮出控件
    .PARAMETER Enabled
        指示是否在启动时启用或禁用贴靠辅助浮出控件
    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "正在启用启动时贴靠辅助浮出控件"
            $value = 1
        } else {
            Write-Host "正在禁用启动时贴靠辅助浮出控件"
            $value = 0
        }
        # taskkill.exe /F /IM "explorer.exe"
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        taskkill.exe /F /IM "explorer.exe"
        Set-ItemProperty -Path $Path -Name EnableSnapAssistFlyout -Value $value
        Start-Process "explorer.exe"
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
