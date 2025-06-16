# 运行 OO Shutup 10

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Run OO Shutup 10",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a039_",
  "Type": "Button",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/OOSUbutton"
}
```

</details>

## 函数：Invoke-WPFOOSU

```powershell
function Invoke-WPFOOSU {
    <#
    .SYNOPSIS
        下载并运行 OO Shutup 10
    #>
    try {
        $OOSU_filepath = "$ENV:temp\OOSU10.exe"
        $Initial_ProgressPreference = $ProgressPreference
        $ProgressPreference = "SilentlyContinue" # 禁用进度条以大幅提高 Invoke-WebRequest 的速度
        Invoke-WebRequest -Uri "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile $OOSU_filepath
        Write-Host "正在启动 OO Shutup 10 ..."
        Start-Process $OOSU_filepath
    } catch {
        Write-Host "下载并运行 OO Shutup 10 时出错" -ForegroundColor Red
    }
    finally {
        $ProgressPreference = $Initial_ProgressPreference
    }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
