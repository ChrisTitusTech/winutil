# Windows 深色主题

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

启用/禁用深色模式。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Dark Theme for Windows",
  "Description": "Enable/Disable Dark Mode.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a100_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Customize-Preferences/DarkMode"
}
```

</details>

## 函数：Invoke-WinUtilDarkMode

```powershell
Function Invoke-WinUtilDarkMode {
    <#

    .SYNOPSIS
        启用/禁用深色模式

    .PARAMETER DarkMoveEnabled
        指示当前的深色模式状态

    #>
    Param($DarkMoveEnabled)
    try {
        if ($DarkMoveEnabled -eq $false) {
            Write-Host "正在启用深色模式"
            $DarkMoveValue = 0
        } else {
            Write-Host "正在禁用深色模式"
            $DarkMoveValue = 1
        }

        $Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        Set-ItemProperty -Path $Path -Name AppsUseLightTheme -Value $DarkMoveValue
        Set-ItemProperty -Path $Path -Name SystemUsesLightTheme -Value $DarkMoveValue
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
