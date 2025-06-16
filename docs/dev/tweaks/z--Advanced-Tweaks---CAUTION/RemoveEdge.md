# 删除 Microsoft Edge

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

当更新重新安装 MS Edge 时将其删除。鸣谢：Techie Jack

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Remove Microsoft Edge",
  "Description": "Removes MS Edge when it gets reinstalled by updates. Credit: Techie Jack",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a029_",
  "InvokeScript": [
    "
         Uninstall-WinUtilEdgeBrowser
        "
  ],
  "UndoScript": [
    "
      Write-Host \"安装 Microsoft Edge\"
      Start-Process -FilePath winget -ArgumentList \"install --force -e --accept-source-agreements --accept-package-agreements --silent Microsoft.Edge \" -NoNewWindow -Wait
      "
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/RemoveEdge"
}
```

</details>

## 调用脚本

```powershell

         Uninstall-WinUtilEdgeBrowser


```
## 撤销脚本

```powershell

      Write-Host "安装 Microsoft Edge"
      Start-Process -FilePath winget -ArgumentList "install --force -e --accept-source-agreements --accept-package-agreements --silent Microsoft.Edge " -NoNewWindow -Wait


```
## 函数：Uninstall-WinUtilEdgeBrowser

```powershell
Function Uninstall-WinUtilEdgeBrowser {

    <#

    .SYNOPSIS
        这将通过将区域更改为爱尔兰然后卸载 Edge 再将其改回来来卸载 Edge

    #>

$msedgeProcess = Get-Process -Name "msedge" -ErrorAction SilentlyContinue
$widgetsProcess = Get-Process -Name "widgets" -ErrorAction SilentlyContinue
# 检查 Microsoft Edge 是否正在运行
if ($msedgeProcess) {
    Stop-Process -Name "msedge" -Force
} else {
    Write-Output "msedge 进程未运行。"
}
# 检查小组件是否正在运行
if ($widgetsProcess) {
    Stop-Process -Name "widgets" -Force
} else {
    Write-Output "小组件进程未运行。"
}

function Uninstall-Process {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $originalNation = [microsoft.win32.registry]::GetValue('HKEY_USERS\.DEFAULT\Control Panel\International\Geo', 'Nation', [Microsoft.Win32.RegistryValueKind]::String)

    # 暂时将国家/地区设置为 84 (法国)
    [microsoft.win32.registry]::SetValue('HKEY_USERS\.DEFAULT\Control Panel\International\Geo', 'Nation', 68, [Microsoft.Win32.RegistryValueKind]::String) | Out-Null

    # 感谢 he3als 提供的 Acl 命令
    $fileName = "IntegratedServicesRegionPolicySet.json"
    $pathISRPS = [Environment]::SystemDirectory + "\" + $fileName
    $aclISRPS = Get-Acl -Path $pathISRPS
    $aclISRPSBackup = [System.Security.AccessControl.FileSecurity]::new()
    $aclISRPSBackup.SetSecurityDescriptorSddlForm($acl.Sddl)
    if (Test-Path -Path $pathISRPS) {
        try {
            $admin = [System.Security.Principal.NTAccount]$(New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')).Translate([System.Security.Principal.NTAccount]).Value

            $aclISRPS.SetOwner($admin)
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($admin, 'FullControl', 'Allow')
            $aclISRPS.AddAccessRule($rule)
            Set-Acl -Path $pathISRPS -AclObject $aclISRPS

            Rename-Item -Path $pathISRPS -NewName ($fileName + '.bak') -Force
        }
        catch {
            Write-Error "[$Mode] 未能为 $pathISRPS 设置所有者"
        }
    }

    $baseKey = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate'
    $registryPath = $baseKey + '\ClientState\' + $Key

    if (!(Test-Path -Path $registryPath)) {
        Write-Host "[$Mode] 注册表项未找到：$registryPath"
        return
    }

    Remove-ItemProperty -Path $registryPath -Name "experiment_control_labels" -ErrorAction SilentlyContinue | Out-Null

    $uninstallString = (Get-ItemProperty -Path $registryPath).UninstallString
    $uninstallArguments = (Get-ItemProperty -Path $registryPath).UninstallArguments

    if ([string]::IsNullOrEmpty($uninstallString) -or [string]::IsNullOrEmpty($uninstallArguments)) {
        Write-Host "[$Mode] 找不到 $Mode 的卸载方法"
        return
    }

    $uninstallArguments += " --force-uninstall --delete-profile"

    # $uninstallCommand = "`"$uninstallString`"" + $uninstallArguments
    if (!(Test-Path -Path $uninstallString)) {
        Write-Host "[$Mode] 在以下位置找不到 setup.exe：$uninstallString"
        return
    }
    Start-Process -FilePath $uninstallString -ArgumentList $uninstallArguments -Wait -NoNewWindow -Verbose

    # 还原 Acl
    if (Test-Path -Path ($pathISRPS + '.bak')) {
        Rename-Item -Path ($pathISRPS + '.bak') -NewName $fileName -Force
        Set-Acl -Path $pathISRPS -AclObject $aclISRPSBackup
    }

    # 还原国家/地区
    [microsoft.win32.registry]::SetValue('HKEY_USERS\.DEFAULT\Control Panel\International\Geo', 'Nation', $originalNation, [Microsoft.Win32.RegistryValueKind]::String) | Out-Null

    if ((Get-ItemProperty -Path $baseKey).IsEdgeStableUninstalled -eq 1) {
        Write-Host "[$Mode] Edge Stable 已成功卸载"
    }
}

function Uninstall-Edge {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" -Name "NoRemove" -ErrorAction SilentlyContinue | Out-Null

    [microsoft.win32.registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdateDev", "AllowUninstall", 1, [Microsoft.Win32.RegistryValueKind]::DWord) | Out-Null

    Uninstall-Process -Key '{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}'

    @( "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
       "$env:PUBLIC\Desktop",
       "$env:USERPROFILE\Desktop" ) | ForEach-Object {
        $shortcutPath = Join-Path -Path $_ -ChildPath "Microsoft Edge.lnk"
        if (Test-Path -Path $shortcutPath) {
            Remove-Item -Path $shortcutPath -Force
        }
    }

}

function Uninstall-WebView {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft EdgeWebView" -Name "NoRemove" -ErrorAction SilentlyContinue | Out-Null

    # 强制使用系统范围的 WebView2
    # [microsoft.win32.registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\WebView2\BrowserExecutableFolder", "*", "%%SystemRoot%%\System32\Microsoft-Edge-WebView")

    Uninstall-Process -Key '{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
}

function Uninstall-EdgeUpdate {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" -Name "NoRemove" -ErrorAction SilentlyContinue | Out-Null

    $registryPath = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate'
    if (!(Test-Path -Path $registryPath)) {
        Write-Host "注册表项未找到：$registryPath"
        return
    }
    $uninstallCmdLine = (Get-ItemProperty -Path $registryPath).UninstallCmdLine

    if ([string]::IsNullOrEmpty($uninstallCmdLine)) {
        Write-Host "找不到 $Mode 的卸载方法"
        return
    }

    Write-Output "正在卸载：$uninstallCmdLine"
    Start-Process cmd.exe "/c $uninstallCmdLine" -WindowStyle Hidden -Wait
}

Uninstall-Edge
    # "WebView" { Uninstall-WebView }
    # "EdgeUpdate" { Uninstall-EdgeUpdate }




}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
