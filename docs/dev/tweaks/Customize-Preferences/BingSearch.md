# 开始菜单中的 Bing 搜索

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

如果启用，则在您的开始菜单搜索中包含来自 Bing 的 Web 搜索结果。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Bing Search in Start Menu",
  "Description": "If enable then includes web search results from Bing in your Start Menu search.",
  "category": "Customize Preferences",
  "panel": "2",
  "Order": "a101_",
  "Type": "Toggle",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Customize-Preferences/BingSearch"
}
```

</details>

## 函数：Invoke-WinUtilBingSearch

```powershell
function Invoke-WinUtilBingSearch {
    <#

    .SYNOPSIS
        禁用/启用 Bing 搜索

    .PARAMETER Enabled
        指示是启用还是禁用 Bing 搜索

    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "正在启用 Bing 搜索"
            $value = 1
        } else {
            Write-Host "正在禁用 Bing 搜索"
            $value = 0
        }
        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
        Set-ItemProperty -Path $Path -Name BingSearchEnabled -Value $value
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
