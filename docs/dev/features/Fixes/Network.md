# 重置网络

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Reset Network",
  "category": "Fixes",
  "Order": "a042_",
  "panel": "1",
  "Type": "Button",
  "ButtonWidth": "300",
  "link": "https://christitustech.github.io/winutil/dev/features/Fixes/Network"
}
```

</details>

## 函数：Invoke-WPFFixesNetwork

```powershell
function Invoke-WPFFixesNetwork {
    <#

    .SYNOPSIS
        重置各种网络配置

    #>

    Write-Host "正在使用 netsh 重置网络"

    # 将 WinSock 目录重置为干净状态
    Start-Process -NoNewWindow -FilePath "netsh" -ArgumentList "winsock", "reset"
    # 将 WinHTTP 代理设置重置为 DIRECT
    Start-Process -NoNewWindow -FilePath "netsh" -ArgumentList "winhttp", "reset", "proxy"
    # 删除所有用户配置的 IP 设置
    Start-Process -NoNewWindow -FilePath "netsh" -ArgumentList "int", "ip", "reset"

    Write-Host "处理完成。请重新启动您的计算机。"

    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageboxTitle = "网络重置 "
    $Messageboxbody = ("已加载默认设置。\n请重新启动您的计算机")
    $MessageIcon = [System.Windows.MessageBoxImage]::Information

    [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)
    Write-Host "=========================================="
    Write-Host "-- 网络配置已重置 --"
    Write-Host "=========================================="
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)
