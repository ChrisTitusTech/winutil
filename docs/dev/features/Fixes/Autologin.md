# 设置自动登录

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Set Up Autologin",
  "category": "Fixes",
  "Order": "a040_",
  "panel": "1",
  "Type": "Button",
  "ButtonWidth": "300",
  "link": "https://christitustech.github.io/winutil/dev/features/Fixes/Autologin"
}
```

</details>

## 函数：Invoke-WPFPanelAutologin

```powershell
function Invoke-WPFPanelAutologin {
    <#

    .SYNOPSIS
        使用 Sysinternals Autologon.exe 启用自动登录

    #>

    # Official Microsoft recommendation: https://learn.microsoft.com/en-us/sysinternals/downloads/autologon
    Invoke-WebRequest -Uri "https://live.sysinternals.com/Autologon.exe" -OutFile "$env:temp\autologin.exe"
    cmd /c "$env:temp\autologin.exe" /accepteula
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)
