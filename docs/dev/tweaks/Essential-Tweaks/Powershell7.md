# 更改 Windows 终端默认值：PowerShell 5 -> PowerShell 7

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

这将编辑 Windows 终端的配置文件，将 PowerShell 5 替换为 PowerShell 7，并在必要时安装 PS7。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Change Windows Terminal default: PowerShell 5 -> PowerShell 7",
  "Description": "This will edit the config file of the Windows Terminal replacing PowerShell 5 with PowerShell 7 and installing PS7 if necessary",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a009_",
  "InvokeScript": [
    "Invoke-WPFTweakPS7 -action \"PS7\""
  ],
  "UndoScript": [
    "Invoke-WPFTweakPS7 -action \"PS5\""
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Essential-Tweaks/Powershell7"
}
```

</details>

## 调用脚本

```powershell
Invoke-WPFTweakPS7 -action "PS7"

```
## 撤销脚本

```powershell
Invoke-WPFTweakPS7 -action "PS5"

```
## 函数：Invoke-WPFTweakPS7

```powershell
function Invoke-WPFTweakPS7{
        <#
    .SYNOPSIS
        这将编辑 Windows 终端的配置文件，将 Powershell 5 替换为 Powershell 7，并在必要时安装 Powershell 7
    .PARAMETER action
        PS7：将 Powershell 7 配置为默认终端
        PS5：将 Powershell 5 配置为默认终端
    #>
    param (
        [ValidateSet("PS7", "PS5")]
        [string]$action
    )

    switch ($action) {
        "PS7"{
            if (Test-Path -Path "$env:ProgramFiles\PowerShell\7") {
                Write-Host "Powershell 7 已安装。"
            } else {
                Write-Host "正在安装 Powershell 7..."
                Install-WinUtilProgramWinget -Action Install -Programs @("Microsoft.PowerShell")
            }
            $targetTerminalName = "PowerShell"
        }
        "PS5"{
            $targetTerminalName = "Windows PowerShell"
        }
    }
    # 检查 Windows 终端是否已安装，如果未安装则返回（以下代码的先决条件）
    if (-not (Get-Command "wt" -ErrorAction SilentlyContinue)) {
        Write-Host "未安装 Windows 终端。正在跳过终端首选项"
        return
    }
    # 检查 Windows 终端 settings.json 文件是否存在，如果不存在则返回（以下代码的先决条件）
    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (-not (Test-Path -Path $settingsPath)) {
        Write-Host "在 $settingsPath 中找不到 Windows 终端设置文件"
        return
    }

    Write-Host "找到设置文件。"
    $settingsContent = Get-Content -Path $settingsPath | ConvertFrom-Json
    $ps7Profile = $settingsContent.profiles.list | Where-Object { $_.name -eq $targetTerminalName }
    if ($ps7Profile) {
        $settingsContent.defaultProfile = $ps7Profile.guid
        $updatedSettings = $settingsContent | ConvertTo-Json -Depth 100
        Set-Content -Path $settingsPath -Value $updatedSettings
        Write-Host "默认配置文件已更新为 " -NoNewline
        Write-Host "$targetTerminalName " -ForegroundColor White -NoNewline
        Write-Host "使用名称属性。"
    } else {
        Write-Host "在 Windows 终端设置中使用名称属性找不到 PowerShell 7 配置文件。"
    }
}

```
## 函数：Install-WinUtilProgramWinget

```powershell
Function Install-WinUtilProgramWinget {
    <#
    .SYNOPSIS
    使用 Winget 对提供的程序运行指定的操作

    .PARAMETER Programs
    要处理的程序列表

    .PARAMETER action
    要对程序执行的操作，可以是“Install”或“Uninstall”

    .NOTES
    当您在普通脚本块中需要 " 时，三重引号是必需的。
    winget 返回代码记录在此处：https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-manager/winget/returnCodes.md
    #>

    param(
        [Parameter(Mandatory, Position=0)]$Programs,

        [Parameter(Mandatory, Position=1)]
        [ValidateSet("Install", "Uninstall")]
        [String]$Action
    )

    Function Invoke-Winget {
    <#
    .SYNOPSIS
    使用提供的参数调用 winget.exe 并返回退出代码

    .PARAMETER wingetId
    Winget 应安装/卸载的程序的 ID

    .PARAMETER scope
    确定安装模式。可以是“user”或“machine”（有关更多信息，请参阅 winget 文档）

    .PARAMETER credential
    应用于运行 winget 的用户的 PSCredential 对象

    .NOTES
    Invoke Winget 使用在函数外部定义的公共变量 $Action 来确定是应安装还是删除程序
    #>
        param (
            [string]$wingetId,
            [string]$scope = "",
            [PScredential]$credential = $null
        )

        $commonArguments = "--id $wingetId --silent"
        $arguments = if ($Action -eq "Install") {
            "install $commonArguments --accept-source-agreements --accept-package-agreements $(if ($scope) {" --scope $scope"})"
        } else {
            "uninstall $commonArguments"
        }

        $processParams = @{
            FilePath = "winget"
            ArgumentList = $arguments
            Wait = $true
            PassThru = $true
            NoNewWindow = $true
        }

        if ($credential) {
            $processParams.credential = $credential
        }

        return (Start-Process @processParams).ExitCode
    }

    Function Invoke-Install {
    <#
    .SYNOPSIS
    包含来自 winget 的安装逻辑和返回代码处理

    .PARAMETER Program
    应安装的程序的 Winget ID
    #>
        param (
            [string]$Program
        )
        $status = Invoke-Winget -wingetId $Program
        if ($status -eq 0) {
            Write-Host "$($Program) 已成功安装。"
            return $true
        } elseif ($status -eq -1978335189) {
            Write-Host "$($Program) 未找到适用的更新"
            return $true
        }

        Write-Host "尝试使用用户范围安装 $($Program)"
        $status = Invoke-Winget -wingetId $Program -scope "user"
        if ($status -eq 0) {
            Write-Host "$($Program) 已成功使用用户范围安装。"
            return $true
        } elseif ($status -eq -1978335189) {
            Write-Host "$($Program) 未找到适用的更新"
            return $true
        }

        $userChoice = [System.Windows.MessageBox]::Show("您是否要尝试使用特定用户凭据安装 $($Program)？选择“是”继续或“否”跳过。", "用户凭据提示", [System.Windows.MessageBoxButton]::YesNo)
        if ($userChoice -eq 'Yes') {
            $getcreds = Get-Credential
            $status = Invoke-Winget -wingetId $Program -credential $getcreds
            if ($status -eq 0) {
                Write-Host "$($Program) 已成功使用用户提示安装。"
                return $true
            }
        } else {
            Write-Host "正在跳过使用特定用户凭据的安装。"
        }

        Write-Host "未能安装 $($Program)。"
        return $false
    }

    Function Invoke-Uninstall {
        <#
        .SYNOPSIS
        包含来自 winget 的卸载逻辑和返回代码处理

        .PARAMETER Program
        应卸载的程序的 Winget ID
        #>
        param (
            [psobject]$Program
        )

        try {
            $status = Invoke-Winget -wingetId $Program
            if ($status -eq 0) {
                Write-Host "$($Program) 已成功卸载。"
                return $true
            } else {
                Write-Host "未能卸载 $($Program)。"
                return $false
            }
        } catch {
            Write-Host "由于错误未能卸载 $($Program)：$_"
            return $false
        }
    }

    $count = $Programs.Count
    $failedPackages = @()

    Write-Host "==========================================="
    Write-Host "--    正在配置 winget 包       ---"
    Write-Host "==========================================="

    for ($i = 0; $i -lt $count; $i++) {
        $Program = $Programs[$i]
        $result = $false
        Set-WinUtilProgressBar -label "$Action $($Program)" -percent ($i / $count * 100)
        $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -value ($i / $count)})

        $result = switch ($Action) {
            "Install" {Invoke-Install -Program $Program}
            "Uninstall" {Invoke-Uninstall -Program $Program}
            default {throw "[Install-WinUtilProgramWinget] 无效操作：$Action"}
        }

        if (-not $result) {
            $failedPackages += $Program
        }
    }

    Set-WinUtilProgressBar -label "$($Action)ation 完成" -percent 100
    return $failedPackages
}

```
## 函数：Set-WinUtilProgressbar

```powershell
function Set-WinUtilProgressbar{
    <#
    .SYNOPSIS
        此函数用于更新 winutil GUI 中显示的进度条。
        如果用户单击某项并且没有进程正在运行，它将自动隐藏
    .PARAMETER Label
        要覆盖在进度条上的文本
    .PARAMETER PERCENT
        应填充的进度条百分比 (0-100)
    .PARAMETER Hide
        如果提供，则将隐藏进度条和标签
    #>
    param(
        [string]$Label,
        [ValidateRange(0,100)]
        [int]$Percent,
        $Hide
    )
    if ($hide) {
        $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBarLabel.Visibility = "Collapsed"})
        $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBar.Visibility = "Collapsed"})
    } else {
        $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBarLabel.Visibility = "Visible"})
        $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBar.Visibility = "Visible"})
    }
    $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBarLabel.Content.Text = $label})
    $sync.form.Dispatcher.Invoke([action]{$sync.ProgressBarLabel.Content.ToolTip = $label})
    $sync.form.Dispatcher.Invoke([action]{ $sync.ProgressBar.Value = $percent})

}

```
## 函数：Set-WinUtilTaskbarItem

```powershell
function Set-WinUtilTaskbaritem {
    <#

    .SYNOPSIS
        修改 WPF 窗体的任务栏项

    .PARAMETER value
        值可以在 0 和 1 之间，0 表示尚未开始进度，1 表示已完全完成
        如果不将状态设置为“Normal”、“Error”或“Paused”，则值不会影响项目
        Set-WinUtilTaskbaritem -value 0.5

    .PARAMETER state
        状态可以是“None”> 无进度，“Indeterminate”> 无限加载灰色，“Normal”> 灰色，“Error”> 红色，“Paused”> 黄色
        不需要值：
        - Set-WinUtilTaskbaritem -state "None"
        - Set-WinUtilTaskbaritem -state "Indeterminate"
        需要值：
        - Set-WinUtilTaskbaritem -state "Error"
        - Set-WinUtilTaskbaritem -state "Normal"
        - Set-WinUtilTaskbaritem -state "Paused"

    .PARAMETER overlay
        要在任务栏项上显示的覆盖图标，有预设的“None”、“logo”和“checkmark”，或者您可以指定图像文件的路径/链接。
        CTT 徽标预设：
        - Set-WinUtilTaskbaritem -overlay "logo"
        复选标记预设：
        - Set-WinUtilTaskbaritem -overlay "checkmark"
        警告预设：
        - Set-WinUtilTaskbaritem -overlay "warning"
        无覆盖：
        - Set-WinUtilTaskbaritem -overlay "None"
        自定义图标（需要受 WPF 支持）：
        - Set-WinUtilTaskbaritem -overlay "C:\path\to\icon.png"

    .PARAMETER description
        要在任务栏项预览中显示的描述
        Set-WinUtilTaskbaritem -description "这是一个描述"
    #>
    param (
        [string]$state,
        [double]$value,
        [string]$overlay,
        [string]$description
    )

    if ($value) {
        $sync["Form"].taskbarItemInfo.ProgressValue = $value
    }

    if ($state) {
        switch ($state) {
            'None' { $sync["Form"].taskbarItemInfo.ProgressState = "None" }
            'Indeterminate' { $sync["Form"].taskbarItemInfo.ProgressState = "Indeterminate" }
            'Normal' { $sync["Form"].taskbarItemInfo.ProgressState = "Normal" }
            'Error' { $sync["Form"].taskbarItemInfo.ProgressState = "Error" }
            'Paused' { $sync["Form"].taskbarItemInfo.ProgressState = "Paused" }
            default { throw "[Set-WinUtilTaskbarItem] 无效状态" }
        }
    }

    if ($overlay) {
        switch ($overlay) {
            'logo' {
                $sync["Form"].taskbarItemInfo.Overlay = "$env:LOCALAPPDATA\winutil\cttlogo.png"
            }
            'checkmark' {
                $sync["Form"].taskbarItemInfo.Overlay = "$env:LOCALAPPDATA\winutil\checkmark.png"
            }
            'warning' {
                $sync["Form"].taskbarItemInfo.Overlay = "$env:LOCALAPPDATA\winutil\warning.png"
            }
            'None' {
                $sync["Form"].taskbarItemInfo.Overlay = $null
            }
            default {
                if (Test-Path $overlay) {
                    $sync["Form"].taskbarItemInfo.Overlay = $overlay
                }
            }
        }
    }

    if ($description) {
        $sync["Form"].taskbarItemInfo.Description = $description
    }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
