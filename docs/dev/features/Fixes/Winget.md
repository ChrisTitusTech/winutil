# WinGet 重新安装

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "WinGet Reinstall",
  "category": "Fixes",
  "panel": "1",
  "Order": "a044_",
  "Type": "Button",
  "ButtonWidth": "300",
  "link": "https://christitustech.github.io/winutil/dev/features/Fixes/Winget"
}
```

</details>

## 函数：Invoke-WPFFixesWinget

```powershell
function Invoke-WPFFixesWinget {

    <#

    .SYNOPSIS
        通过运行 choco install winget 修复 Winget
    .DESCRIPTION
        感谢 BravoNorris 提出了一个重新安装 winget 按钮的绝佳主意
    #>
    # 如果 Choco 尚不存在，则安装它
    Install-WinUtilChoco
    Start-Process -FilePath "choco" -ArgumentList "install winget -y --force" -NoNewWindow -Wait

}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)
