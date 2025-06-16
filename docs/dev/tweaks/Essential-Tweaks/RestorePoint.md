# 创建还原点

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

在运行时创建还原点，以便在需要从 WinUtil 修改中还原时使用

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Create Restore Point",
  "Description": "Creates a restore point at runtime in case a revert is needed from WinUtil modifications",
  "category": "Essential Tweaks",
  "panel": "1",
  "Checked": "False",
  "Order": "a001_",
  "InvokeScript": [
    "
        # Check if the user has administrative privileges
        if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Host \"Please run this script as an administrator.\"
            return
        }

        # Check if System Restore is enabled for the main drive
        try {
            # Try getting restore points to check if System Restore is enabled
            Enable-ComputerRestore -Drive \"$env:SystemDrive\"
        } catch {
            Write-Host \"An error occurred while enabling System Restore: $_\"
        }

        # Check if the SystemRestorePointCreationFrequency value exists
        $exists = Get-ItemProperty -path \"HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\SystemRestore\" -Name \"SystemRestorePointCreationFrequency\" -ErrorAction SilentlyContinue
        if($null -eq $exists) {
            write-host 'Changing system to allow multiple restore points per day'
            Set-ItemProperty -Path \"HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\SystemRestore\" -Name \"SystemRestorePointCreationFrequency\" -Value \"0\" -Type DWord -Force -ErrorAction Stop | Out-Null
        }

        # Attempt to load the required module for Get-ComputerRestorePoint
        try {
            Import-Module Microsoft.PowerShell.Management -ErrorAction Stop
        } catch {
            Write-Host \"Failed to load the Microsoft.PowerShell.Management module: $_\"
            return
        }

        # Get all the restore points for the current day
        try {
            $existingRestorePoints = Get-ComputerRestorePoint | Where-Object { $_.CreationTime.Date -eq (Get-Date).Date }
        } catch {
            Write-Host \"Failed to retrieve restore points: $_\"
            return
        }

        # Check if there is already a restore point created today
        if ($existingRestorePoints.Count -eq 0) {
            $description = \"System Restore Point created by WinUtil\"

            Checkpoint-Computer -Description $description -RestorePointType \"MODIFY_SETTINGS\"
            Write-Host -ForegroundColor Green \"System Restore Point Created Successfully\"
        }
      "
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Essential-Tweaks/RestorePoint"
}
```

</details>

## 调用脚本

```powershell

        # 检查用户是否具有管理员权限
        if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Host "请以管理员身份运行此脚本。"
            return
        }

        # 检查主驱动器是否启用了系统还原
        try {
            # 尝试获取还原点以检查是否启用了系统还原
            Enable-ComputerRestore -Drive "$env:SystemDrive"
        } catch {
            Write-Host "启用系统还原时出错：$_"
        }

        # 检查 SystemRestorePointCreationFrequency 值是否存在
        $exists = Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -ErrorAction SilentlyContinue
        if($null -eq $exists) {
            write-host '正在更改系统以允许每天创建多个还原点'
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value "0" -Type DWord -Force -ErrorAction Stop | Out-Null
        }

        # 尝试加载 Get-ComputerRestorePoint 所需的模块
        try {
            Import-Module Microsoft.PowerShell.Management -ErrorAction Stop
        } catch {
            Write-Host "加载 Microsoft.PowerShell.Management 模块失败：$_"
            return
        }

        # 获取当天的所有还原点
        try {
            $existingRestorePoints = Get-ComputerRestorePoint | Where-Object { $_.CreationTime.Date -eq (Get-Date).Date }
        } catch {
            Write-Host "检索还原点失败：$_"
            return
        }

        # 检查今天是否已创建还原点
        if ($existingRestorePoints.Count -eq 0) {
            $description = "由 WinUtil 创建的系统还原点"

            Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS"
            Write-Host -ForegroundColor Green "系统还原点已成功创建"
        }


```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
