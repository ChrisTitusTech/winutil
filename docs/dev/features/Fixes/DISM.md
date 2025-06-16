# 系统损坏扫描

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "System Corruption Scan",
  "category": "Fixes",
  "panel": "1",
  "Order": "a043_",
  "Type": "Button",
  "ButtonWidth": "300",
  "link": "https://christitustech.github.io/winutil/dev/features/Fixes/DISM"
}
```

</details>

## 函数：Invoke-WPFPanelDISM

```powershell
function Invoke-WPFPanelDISM {
    <#

    .SYNOPSIS
        使用 Chkdsk、SFC 和 DISM 检查系统损坏情况

    .DESCRIPTION
        1. Chkdsk - 修复磁盘和文件系统损坏
        2. SFC 运行 1 - 修复系统文件损坏，如果 DISM 已损坏则修复 DISM
        3. DISM - 修复系统映像损坏，如果 SFC 的系统映像已损坏则修复 SFC 的系统映像
        4. SFC 运行 2 - 修复系统文件损坏，这次使用几乎可以保证未损坏的系统映像

    .NOTES
        命令参数：
            1. Chkdsk
                /Scan - 在系统驱动器上运行联机扫描，尝试修复任何损坏，并将其他损坏排队以便在重新启动时修复
            2. SFC
                /ScanNow - 执行系统文件扫描并修复任何损坏
            3. DISM - 修复系统映像损坏，如果 SFC 的系统映像已损坏则修复 SFC 的系统映像
                /Online - 修复当前正在运行的系统映像
                /Cleanup-Image - 对映像执行清理操作，可能会删除一些不需要的临时文件
                /Restorehealth - 执行映像扫描并修复任何损坏

    #>
    Start-Process PowerShell -ArgumentList "Write-Host '(1/4) Chkdsk' -ForegroundColor Green; Chkdsk /scan;
    Write-Host '`n(2/4) SFC - 1st scan' -ForegroundColor Green; sfc /scannow;
    Write-Host '`n(3/4) DISM' -ForegroundColor Green; DISM /Online /Cleanup-Image /Restorehealth;
    Write-Host '`n(4/4) SFC - 2nd scan' -ForegroundColor Green; sfc /scannow;
    Read-Host '`nPress Enter to Continue'" -verb runas
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)
