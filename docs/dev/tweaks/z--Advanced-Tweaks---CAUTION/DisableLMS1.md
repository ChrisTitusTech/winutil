# 禁用 Intel MM (vPro LMS)

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

Intel LMS 服务始终在所有端口上侦听，可能存在巨大的安全风险。没有必要在家庭计算机上运行 LMS，即使在企业中也有更好的解决方案。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Disable Intel MM (vPro LMS)",
  "Description": "Intel LMS service is always listening on all ports and could be a huge security risk. There is no need to run LMS on home machines and even in the Enterprise there are better solutions.",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a026_",
  "InvokeScript": [
    "
        Write-Host \"终止 LMS\"
        $serviceName = \"LMS\"
        Write-Host \"正在停止并禁用服务：$serviceName\"
        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue;
        Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue;

        Write-Host \"正在删除服务：$serviceName\";
        sc.exe delete $serviceName;

        Write-Host \"正在删除 LMS 驱动程序包\";
        $lmsDriverPackages = Get-ChildItem -Path \"C:\\Windows\\System32\\DriverStore\\FileRepository\" -Recurse -Filter \"lms.inf*\";
        foreach ($package in $lmsDriverPackages) {
            Write-Host \"正在删除驱动程序包：$($package.Name)\";
            pnputil /delete-driver $($package.Name) /uninstall /force;
        }
        if ($lmsDriverPackages.Count -eq 0) {
            Write-Host \"在驱动程序存储中未找到 LMS 驱动程序包。\";
        } else {
            Write-Host \"已删除所有找到的 LMS 驱动程序包。\";
        }

        Write-Host \"正在搜索并删除 LMS 可执行文件\";
        $programFilesDirs = @(\"C:\\Program Files\", \"C:\\Program Files (x86)\");
        $lmsFiles = @();
        foreach ($dir in $programFilesDirs) {
            $lmsFiles += Get-ChildItem -Path $dir -Recurse -Filter \"LMS.exe\" -ErrorAction SilentlyContinue;
        }
        foreach ($file in $lmsFiles) {
            Write-Host \"正在获取文件所有权：$($file.FullName)\";
            & icacls $($file.FullName) /grant Administrators:F /T /C /Q;
            & takeown /F $($file.FullName) /A /R /D Y;
            Write-Host \"正在删除文件：$($file.FullName)\";
            Remove-Item $($file.FullName) -Force -ErrorAction SilentlyContinue;
        }
        if ($lmsFiles.Count -eq 0) {
            Write-Host \"在 Program Files 目录中未找到 LMS.exe 文件。\";
        } else {
            Write-Host \"已删除所有找到的 LMS.exe 文件。\";
        }
        Write-Host 'Intel LMS vPro 服务已被禁用、删除和阻止。';
       "
  ],
  "UndoScript": [
    "
      Write-Host \"需要从 intel.com 重新下载 LMS vPro\"

      "
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/DisableLMS1"
}
```

</details>

## 调用脚本

```powershell

        Write-Host "终止 LMS"
        $serviceName = "LMS"
        Write-Host "正在停止并禁用服务：$serviceName"
        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue;
        Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue;

        Write-Host "正在删除服务：$serviceName";
        sc.exe delete $serviceName;

        Write-Host "正在删除 LMS 驱动程序包";
        $lmsDriverPackages = Get-ChildItem -Path "C:\Windows\System32\DriverStore\FileRepository" -Recurse -Filter "lms.inf*";
        foreach ($package in $lmsDriverPackages) {
            Write-Host "正在删除驱动程序包：$($package.Name)";
            pnputil /delete-driver $($package.Name) /uninstall /force;
        }
        if ($lmsDriverPackages.Count -eq 0) {
            Write-Host "在驱动程序存储中未找到 LMS 驱动程序包。";
        } else {
            Write-Host "已删除所有找到的 LMS 驱动程序包。";
        }

        Write-Host "正在搜索并删除 LMS 可执行文件";
        $programFilesDirs = @("C:\Program Files", "C:\Program Files (x86)");
        $lmsFiles = @();
        foreach ($dir in $programFilesDirs) {
            $lmsFiles += Get-ChildItem -Path $dir -Recurse -Filter "LMS.exe" -ErrorAction SilentlyContinue;
        }
        foreach ($file in $lmsFiles) {
            Write-Host "正在获取文件所有权：$($file.FullName)";
            & icacls $($file.FullName) /grant Administrators:F /T /C /Q;
            & takeown /F $($file.FullName) /A /R /D Y;
            Write-Host "正在删除文件：$($file.FullName)";
            Remove-Item $($file.FullName) -Force -ErrorAction SilentlyContinue;
        }
        if ($lmsFiles.Count -eq 0) {
            Write-Host "在 Program Files 目录中未找到 LMS.exe 文件。";
        } else {
            Write-Host "已删除所有找到的 LMS.exe 文件。";
        }
        Write-Host 'Intel LMS vPro 服务已被禁用、删除和阻止。';


```
## 撤销脚本

```powershell

      Write-Host "需要从 intel.com 重新下载 LMS vPro"



```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
