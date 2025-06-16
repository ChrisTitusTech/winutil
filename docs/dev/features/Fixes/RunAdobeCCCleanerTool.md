# 删除 Adobe Creative Cloud

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Remove Adobe Creative Cloud",
  "category": "Fixes",
  "panel": "1",
  "Order": "a045_",
  "Type": "Button",
  "ButtonWidth": "300",
  "link": "https://christitustech.github.io/winutil/dev/features/Fixes/RunAdobeCCCleanerTool"
}
```

</details>

## 函数：Invoke-WPFRunAdobeCCCleanerTool

```powershell
function Invoke-WPFRunAdobeCCCleanerTool {
    <#
    .SYNOPSIS
        它会删除或修复问题文件，并解决注册表项中的权限问题。
    .DESCRIPTION
        Creative Cloud Cleaner 工具是一款供有经验的用户清理损坏安装的实用程序。
    #>

    [string]$url="https://swupmf.adobe.com/webfeed/CleanerTool/win/AdobeCreativeCloudCleanerTool.exe"

    Write-Host "Adobe Creative Cloud Cleaner 工具托管在"
    Write-Host "$url"

    try {
        # 不要显示进度，因为它会降低下载速度
        $ProgressPreference='SilentlyContinue'

        Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\AdobeCreativeCloudCleanerTool.exe" -UseBasicParsing -ErrorAction SilentlyContinue -Verbose

        # 获取所需文件后，将 ProgressPreference 变量恢复为默认值
        $ProgressPreference='Continue'

        Start-Process -FilePath "$env:TEMP\AdobeCreativeCloudCleanerTool.exe" -Wait -ErrorAction SilentlyContinue -Verbose
    } catch {
        Write-Error $_.Exception.Message
    } finally {
        if (Test-Path -Path "$env:TEMP\AdobeCreativeCloudCleanerTool.exe") {
            Write-Host "正在清理..."
            Remove-Item -Path "$env:TEMP\AdobeCreativeCloudCleanerTool.exe" -Verbose
        }
    }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)
