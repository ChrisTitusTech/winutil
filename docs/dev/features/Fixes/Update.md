# 重置 Windows 更新

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Reset Windows Update",
  "category": "Fixes",
  "panel": "1",
  "Order": "a041_",
  "Type": "Button",
  "ButtonWidth": "300",
  "link": "https://christitustech.github.io/winutil/dev/features/Fixes/Update"
}
```

</details>

## 函数：Invoke-WPFFixesUpdate

```powershell
function Invoke-WPFFixesUpdate {

    <#

    .SYNOPSIS
        执行各种任务以尝试修复 Windows 更新

    .DESCRIPTION
        1. （仅限积极模式）使用 chkdsk、SFC 和 DISM 扫描系统是否存在损坏
            步骤：
                1. 运行 chkdsk /scan /perf
                    /scan - 在卷上运行联机扫描
                    /perf - 使用更多系统资源以尽快完成扫描
                2. 运行 SFC /scannow
                    /scannow - 扫描所有受保护系统文件的完整性，并在可能的情况下修复有问题的文件
                3. 运行 DISM /Online /Cleanup-Image /RestoreHealth
                    /Online - 针对正在运行的操作系统
                    /Cleanup-Image - 对映像执行清理和恢复操作
                    /RestoreHealth - 扫描映像是否存在组件存储损坏，并尝试使用 Windows 更新修复损坏
                4. 运行 SFC /scannow
                    如果 DISM 修复了 SFC，则运行两次
        2. 停止 Windows 更新服务
        3. 删除存储 BITS 作业的 QMGR 数据文件
        4. （仅限积极模式）重命名 DataStore 和 CatRoot2 文件夹
            DataStore - 包含 Windows 更新历史记录和日志文件
            CatRoot2 - 包含 Windows 更新包的签名
        5. 重命名 Windows 更新下载文件夹
        6. 删除 Windows 更新日志
        7. （仅限积极模式）重置 Windows 更新服务的安全描述符
        8. 重新注册 BITS 和 Windows 更新 DLL
        9. 删除 WSUS 客户端设置
        10. 重置 WinSock
        11. 获取并删除所有 BITS 作业
        12. 设置 Windows 更新服务的启动类型然后启动它们
        13. 强制 Windows 更新检查更新

    .PARAMETER Aggressive
        如果指定，脚本将采取额外的步骤来修复 Windows 更新，这些步骤更危险、花费大量时间或通常不必要

    #>

    param($Aggressive = $false)

    Write-Progress -Id 0 -Activity "正在修复 Windows 更新" -PercentComplete 0
    # 等待第一个进度条显示，否则第二个进度条不会显示
    Start-Sleep -Milliseconds 200

    if ($Aggressive) {
        # 扫描系统是否存在损坏
        Write-Progress -Id 0 -Activity "正在修复 Windows 更新" -Status "正在扫描损坏..." -PercentComplete 0
        Write-Progress -Id 1 -ParentId 0 -Activity "正在扫描损坏" -Status "正在运行 chkdsk..." -PercentComplete 0
        # 2>&1 重定向 stdout，允许遍历输出
        chkdsk.exe /scan /perf 2>&1 | ForEach-Object {
            # 将 stdout 写入 Verbose 流
            Write-Verbose $_

            # 获取总百分比的索引
            $index = $_.IndexOf("Total:")
            if (
                # 如果找到百分比
                ($percent = try {(
                    $_.Substring(
                        $index + 6,
                        $_.IndexOf("%", $index) - $index - 6
                    )
                ).Trim()} catch {0}) `
                <# 并且当前百分比大于前一个百分比 #>`
                -and $percent -gt $oldpercent
            ) {
                # 更新进度条
                $oldpercent = $percent
                Write-Progress -Id 1 -ParentId 0 -Activity "正在扫描损坏" -Status "正在运行 chkdsk... ($percent%)" -PercentComplete $percent
            }
        }

        Write-Progress -Id 1 -ParentId 0 -Activity "正在扫描损坏" -Status "正在运行 SFC..." -PercentComplete 0
        $oldpercent = 0
        # SFC 在重定向时存在一个错误，导致它仅在 stdout 缓冲区已满时才输出，从而导致进度条成块移动
        sfc /scannow 2>&1 | ForEach-Object {
            # 将 stdout 写入 Verbose 流
            Write-Verbose $_

            # 筛选包含大于前一个百分比的百分比的行
            if (
                (
                    # 使用不同的方法获取考虑 SFC Unicode 输出的百分比
                    [int]$percent = try {(
                        (
                            $_.Substring(
                                $_.IndexOf("n") + 2,
                                $_.IndexOf("%") - $_.IndexOf("n") - 2
                            ).ToCharArray() | Where-Object {$_}
                        ) -join ''
                    ).TrimStart()} catch {0}
                ) -and $percent -gt $oldpercent
            ) {
                # 更新进度条
                $oldpercent = $percent
                Write-Progress -Id 1 -ParentId 0 -Activity "正在扫描损坏" -Status "正在运行 SFC... ($percent%)" -PercentComplete $percent
            }
        }

        Write-Progress -Id 1 -ParentId 0 -Activity "正在扫描损坏" -Status "正在运行 DISM..." -PercentComplete 0
        $oldpercent = 0
        DISM /Online /Cleanup-Image /RestoreHealth | ForEach-Object {
            # 将 stdout 写入 Verbose 流
            Write-Verbose $_

            # 筛选包含大于前一个百分比的百分比的行
            if (
                ($percent = try {
                    [int]($_ -replace "\[" -replace "=" -replace " " -replace "%" -replace "\]")
                } catch {0}) `
                -and $percent -gt $oldpercent
            ) {
                # 更新进度条
                $oldpercent = $percent
                Write-Progress -Id 1 -ParentId 0 -Activity "正在扫描损坏" -Status "正在运行 DISM... ($percent%)" -PercentComplete $percent
            }
        }

        Write-Progress -Id 1 -ParentId 0 -Activity "正在扫描损坏" -Status "再次运行 SFC..." -PercentComplete 0
        $oldpercent = 0
        sfc /scannow 2>&1 | ForEach-Object {
            # 将 stdout 写入 Verbose 流
            Write-Verbose $_

            # 筛选包含大于前一个百分比的百分比的行
            if (
                (
                    [int]$percent = try {(
                        (
                            $_.Substring(
                                $_.IndexOf("n") + 2,
                                $_.IndexOf("%") - $_.IndexOf("n") - 2
                            ).ToCharArray() | Where-Object {$_}
                        ) -join ''
                    ).TrimStart()} catch {0}
                ) -and $percent -gt $oldpercent
            ) {
                # 更新进度条
                $oldpercent = $percent
                Write-Progress -Id 1 -ParentId 0 -Activity "正在扫描损坏" -Status "正在运行 SFC... ($percent%)" -PercentComplete $percent
            }
        }
        Write-Progress -Id 1 -ParentId 0 -Activity "正在扫描损坏" -Status "已完成" -PercentComplete 100
    }


    Write-Progress -Id 0 -Activity "正在修复 Windows 更新" -Status "正在停止 Windows 更新服务..." -PercentComplete 10
    # 停止 Windows 更新服务
    Write-Progress -Id 2 -ParentId 0 -Activity "正在停止服务" -Status "正在停止 BITS..." -PercentComplete 0
    Stop-Service -Name BITS -Force
    Write-Progress -Id 2 -ParentId 0 -Activity "正在停止服务" -Status "正在停止 wuauserv..." -PercentComplete 20
    Stop-Service -Name wuauserv -Force
    Write-Progress -Id 2 -ParentId 0 -Activity "正在停止服务" -Status "正在停止 appidsvc..." -PercentComplete 40
    Stop-Service -Name appidsvc -Force
    Write-Progress -Id 2 -ParentId 0 -Activity "正在停止服务" -Status "正在停止 cryptsvc..." -PercentComplete 60
    Stop-Service -Name cryptsvc -Force
    Write-Progress -Id 2 -ParentId 0 -Activity "正在停止服务" -Status "已完成" -PercentComplete 100


    # 删除 QMGR 数据文件
    Write-Progress -Id 0 -Activity "正在修复 Windows 更新" -Status "正在重命名/删除文件..." -PercentComplete 20
    Write-Progress -Id 3 -ParentId 0 -Activity "正在重命名/删除文件" -Status "正在删除 QMGR 数据文件..." -PercentComplete 0
    Remove-Item "$env:allusersprofile\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -ErrorAction SilentlyContinue


    if ($Aggressive) {
        # 重命名 Windows 更新日志和签名文件夹
        Write-Progress -Id 3 -ParentId 0 -Activity "正在重命名/删除文件" -Status "正在重命名 Windows 更新日志、下载和签名文件夹..." -PercentComplete 20
        Rename-Item $env:systemroot\SoftwareDistribution\DataStore DataStore.bak -ErrorAction SilentlyContinue
        Rename-Item $env:systemroot\System32\Catroot2 catroot2.bak -ErrorAction SilentlyContinue
    }

    # 重命名 Windows 更新下载文件夹
    Write-Progress -Id 3 -ParentId 0 -Activity "正在重命名/删除文件" -Status "正在重命名 Windows 更新下载文件夹..." -PercentComplete 20
    Rename-Item $env:systemroot\SoftwareDistribution\Download Download.bak -ErrorAction SilentlyContinue

    # 删除旧版 Windows 更新日志
    Write-Progress -Id 3 -ParentId 0 -Activity "正在重命名/删除文件" -Status "正在删除旧的 Windows 更新日志..." -PercentComplete 80
    Remove-Item $env:systemroot\WindowsUpdate.log -ErrorAction SilentlyContinue
    Write-Progress -Id 3 -ParentId 0 -Activity "正在重命名/删除文件" -Status "已完成" -PercentComplete 100


    if ($Aggressive) {
        # 重置 Windows 更新服务的安全描述符
        Write-Progress -Id 0 -Activity "正在修复 Windows 更新" -Status "正在重置 WU 服务安全描述符..." -PercentComplete 25
        Write-Progress -Id 4 -ParentId 0 -Activity "正在重置 WU 服务安全描述符" -Status "正在重置 BITS 安全描述符..." -PercentComplete 0
        Start-Process -NoNewWindow -FilePath "sc.exe" -ArgumentList "sdset", "bits", "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"
        Write-Progress -Id 4 -ParentId 0 -Activity "正在重置 WU 服务安全描述符" -Status "正在重置 wuauserv 安全描述符..." -PercentComplete 50
        Start-Process -NoNewWindow -FilePath "sc.exe" -ArgumentList "sdset", "wuauserv", "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"
        Write-Progress -Id 4 -ParentId 0 -Activity "正在重置 WU 服务安全描述符" -Status "已完成" -PercentComplete 100
    }


    # 重新注册 BITS 和 Windows 更新 DLL
    Write-Progress -Id 0 -Activity "正在修复 Windows 更新" -Status "正在重新注册 DLL..." -PercentComplete 40
    $oldLocation = Get-Location
    Set-Location $env:systemroot\system32
    $i = 0
    $DLLs = @(
        "atl.dll", "urlmon.dll", "mshtml.dll", "shdocvw.dll", "browseui.dll",
        "jscript.dll", "vbscript.dll", "scrrun.dll", "msxml.dll", "msxml3.dll",
        "msxml6.dll", "actxprxy.dll", "softpub.dll", "wintrust.dll", "dssenh.dll",
        "rsaenh.dll", "gpkcsp.dll", "sccbase.dll", "slbcsp.dll", "cryptdlg.dll",
        "oleaut32.dll", "ole32.dll", "shell32.dll", "initpki.dll", "wuapi.dll",
        "wuaueng.dll", "wuaueng1.dll", "wucltui.dll", "wups.dll", "wups2.dll",
        "wuweb.dll", "qmgr.dll", "qmgrprxy.dll", "wucltux.dll", "muweb.dll", "wuwebv.dll"
    )
    foreach ($dll in $DLLs) {
        Write-Progress -Id 5 -ParentId 0 -Activity "正在重新注册 DLL" -Status "正在注册 $dll..." -PercentComplete ($i / $DLLs.Count * 100)
        $i++
        Start-Process -NoNewWindow -FilePath "regsvr32.exe" -ArgumentList "/s", $dll
    }
    Set-Location $oldLocation
    Write-Progress -Id 5 -ParentId 0 -Activity "正在重新注册 DLL" -Status "已完成" -PercentComplete 100


    # 删除 WSUS 客户端设置
    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate") {
        Write-Progress -Id 0 -Activity "正在修复 Windows 更新" -Status "正在删除 WSUS 客户端设置..." -PercentComplete 60
        Write-Progress -Id 6 -ParentId 0 -Activity "正在删除 WSUS 客户端设置" -PercentComplete 0
        Start-Process -NoNewWindow -FilePath "REG" -ArgumentList "DELETE", "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate", "/v", "AccountDomainSid", "/f" -RedirectStandardError $true
        Start-Process -NoNewWindow -FilePath "REG" -ArgumentList "DELETE", "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate", "/v", "PingID", "/f" -RedirectStandardError $true
        Start-Process -NoNewWindow -FilePath "REG" -ArgumentList "DELETE", "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate", "/v", "SusClientId", "/f" -RedirectStandardError $true
        Write-Progress -Id 6 -ParentId 0 -Activity "正在删除 WSUS 客户端设置" -Status "已完成" -PercentComplete 100
    }


    # 重置 WinSock
    Write-Progress -Id 0 -Activity "正在修复 Windows 更新" -Status "正在重置 WinSock..." -PercentComplete 65
    Write-Progress -Id 7 -ParentId 0 -Activity "正在重置 WinSock" -Status "正在重置 WinSock..." -PercentComplete 0
    Start-Process -NoNewWindow -FilePath "netsh" -ArgumentList "winsock", "reset" -RedirectStandardOutput $true
    Start-Process -NoNewWindow -FilePath "netsh" -ArgumentList "winhttp", "reset", "proxy" -RedirectStandardOutput $true
    Start-Process -NoNewWindow -FilePath "netsh" -ArgumentList "int", "ip", "reset" -RedirectStandardOutput $true
    Write-Progress -Id 7 -ParentId 0 -Activity "正在重置 WinSock" -Status "已完成" -PercentComplete 100


    # 获取并删除所有 BITS 作业
    Write-Progress -Id 0 -Activity "正在修复 Windows 更新" -Status "正在删除 BITS 作业..." -PercentComplete 75
    Write-Progress -Id 8 -ParentId 0 -Activity "正在删除 BITS 作业" -Status "正在删除 BITS 作业..." -PercentComplete 0
    Get-BitsTransfer | Remove-BitsTransfer
    Write-Progress -Id 8 -ParentId 0 -Activity "正在删除 BITS 作业" -Status "已完成" -PercentComplete 100


    # 更改 Windows 更新服务的启动类型并启动它们
    Write-Progress -Id 0 -Activity "正在修复 Windows 更新" -Status "正在启动 Windows 更新服务..." -PercentComplete 90
    Write-Progress -Id 9 -ParentId 0 -Activity "正在启动 Windows 更新服务" -Status "正在启动 BITS..." -PercentComplete 0
    Get-Service BITS | Set-Service -StartupType Manual -PassThru | Start-Service
    Write-Progress -Id 9 -ParentId 0 -Activity "正在启动 Windows 更新服务" -Status "正在启动 wuauserv..." -PercentComplete 25
    Get-Service wuauserv | Set-Service -StartupType Manual -PassThru | Start-Service
    Write-Progress -Id 9 -ParentId 0 -Activity "正在启动 Windows 更新服务" -Status "正在启动 AppIDSvc..." -PercentComplete 50
    # AppIDSvc 服务受保护，因此必须在注册表中更改启动类型
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\AppIDSvc" -Name "Start" -Value "3" # 手动
    Start-Service AppIDSvc
    Write-Progress -Id 9 -ParentId 0 -Activity "正在启动 Windows 更新服务" -Status "正在启动 CryptSvc..." -PercentComplete 75
    Get-Service CryptSvc | Set-Service -StartupType Manual -PassThru | Start-Service
    Write-Progress -Id 9 -ParentId 0 -Activity "正在启动 Windows 更新服务" -Status "已完成" -PercentComplete 100


    # 强制 Windows 更新检查更新
    Write-Progress -Id 0 -Activity "正在修复 Windows 更新" -Status "正在强制发现..." -PercentComplete 95
    Write-Progress -Id 10 -ParentId 0 -Activity "正在强制发现" -Status "正在强制发现..." -PercentComplete 0
    (New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()
    Start-Process -NoNewWindow -FilePath "wuauclt" -ArgumentList "/resetauthorization", "/detectnow"
    Write-Progress -Id 10 -ParentId 0 -Activity "正在强制发现" -Status "已完成" -PercentComplete 100
    Write-Progress -Id 0 -Activity "正在修复 Windows 更新" -Status "已完成" -PercentComplete 100

    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageboxTitle = "重置 Windows 更新 "
    $Messageboxbody = ("已加载默认设置。\n请重新启动您的计算机")
    $MessageIcon = [System.Windows.MessageBoxImage]::Information

    [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)
    Write-Host "==============================================="
    Write-Host "-- 将所有 Windows 更新设置重置为默认值 -"
    Write-Host "==============================================="

    # 删除进度条
    Write-Progress -Id 0 -Activity "正在修复 Windows 更新" -Completed
    Write-Progress -Id 1 -Activity "正在扫描损坏" -Completed
    Write-Progress -Id 2 -Activity "正在停止服务" -Completed
    Write-Progress -Id 3 -Activity "正在重命名/删除文件" -Completed
    Write-Progress -Id 4 -Activity "正在重置 WU 服务安全描述符" -Completed
    Write-Progress -Id 5 -Activity "正在重新注册 DLL" -Completed
    Write-Progress -Id 6 -Activity "正在删除 WSUS 客户端设置" -Completed
    Write-Progress -Id 7 -Activity "正在重置 WinSock" -Completed
    Write-Progress -Id 8 -Activity "正在删除 BITS 作业" -Completed
    Write-Progress -Id 9 -Activity "正在启动 Windows 更新服务" -Completed
    Write-Progress -Id 10 -Activity "正在强制发现" -Completed
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)
