# 粘滞键

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

如果启用，则激活粘滞键 - 粘滞键是一些图形用户界面的辅助功能，可帮助有身体残疾的用户或帮助用户减少重复性劳损。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Sticky Keys",
  "Description": "If Enabled then Sticky Keys is activated - Sticky keys is an accessibility feature of some graphical user interfaces which assists users who have physical disabilities or help users reduce repetitive strain injury.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a108_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Customize-Preferences/StickyKeys"
}
```

</details>

## 函数：Invoke-WinUtilStickyKeys

```powershell
Function Invoke-WinUtilStickyKeys {
    <#
    .SYNOPSIS
        在启动时禁用/启用粘滞键
    .PARAMETER Enabled
        指示是否在启动时启用或禁用粘滞键
    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "正在启用启动时粘滞键"
            $value = 510
        } else {
            Write-Host "正在禁用启动时粘滞键"
            $value = 58
        }
        $Path = "HKCU:\Control Panel\Accessibility\StickyKeys"
        Set-ItemProperty -Path $Path -Name Flags -Value $value
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
