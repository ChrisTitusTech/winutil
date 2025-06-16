# 禁用遥测

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

禁用 Microsoft 遥测。注意：这将锁定许多 Edge 浏览器设置。使用 Edge 浏览器时，Microsoft 会对您进行大量监视。

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Disable Telemetry",
  "Description": "Disables Microsoft Telemetry. Note: This will lock many Edge Browser settings. Microsoft spies heavily on you when using the Edge browser.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a003_",
  "ScheduledTask": [
    {
      "Name": "Microsoft\\Windows\\Application Experience\\Microsoft Compatibility Appraiser",
      "State": "Disabled",
      "OriginalState": "Enabled"
    },
    {
      "Name": "Microsoft\\Windows\\Application Experience\\ProgramDataUpdater",
      "State": "Disabled",
      "OriginalState": "Enabled"
    },
    {
      "Name": "Microsoft\\Windows\\Autochk\\Proxy",
      "State": "Disabled",
      "OriginalState": "Enabled"
    },
    {
      "Name": "Microsoft\\Windows\\Customer Experience Improvement Program\\Consolidator",
      "State": "Disabled",
      "OriginalState": "Enabled"
    },
    {
      "Name": "Microsoft\\Windows\\Customer Experience Improvement Program\\UsbCeip",
      "State": "Disabled",
      "OriginalState": "Enabled"
    },
    {
      "Name": "Microsoft\\Windows\\DiskDiagnostic\\Microsoft-Windows-DiskDiagnosticDataCollector",
      "State": "Disabled",
      "OriginalState": "Enabled"
    },
    {
      "Name": "Microsoft\\Windows\\Feedback\\Siuf\\DmClient",
      "State": "Disabled",
      "OriginalState": "Enabled"
    },
    {
      "Name": "Microsoft\\Windows\\Feedback\\Siuf\\DmClientOnScenarioDownload",
      "State": "Disabled",
      "OriginalState": "Enabled"
    },
    {
      "Name": "Microsoft\\Windows\\Windows Error Reporting\\QueueReporting",
      "State": "Disabled",
      "OriginalState": "Enabled"
    },
    {
      "Name": "Microsoft\\Windows\\Application Experience\\MareBackup",
      "State": "Disabled",
      "OriginalState": "Enabled"
    },
    {
      "Name": "Microsoft\\Windows\\Application Experience\\StartupAppTask",
      "State": "Disabled",
      "OriginalState": "Enabled"
    },
    {
      "Name": "Microsoft\\Windows\\Application Experience\\PcaPatchDbTask",
      "State": "Disabled",
      "OriginalState": "Enabled"
    },
    {
      "Name": "Microsoft\\Windows\\Maps\\MapsUpdateTask",
      "State": "Disabled",
      "OriginalState": "Enabled"
    }
  ],
  "registry": [
    {
      "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\DataCollection",
      "Type": "DWord",
      "Value": "0",
      "Name": "AllowTelemetry",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection",
      "OriginalValue": "1",
      "Name": "AllowTelemetry",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
      "OriginalValue": "1",
      "Name": "ContentDeliveryAllowed",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
      "OriginalValue": "1",
      "Name": "OemPreInstalledAppsEnabled",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
      "OriginalValue": "1",
      "Name": "PreInstalledAppsEnabled",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
      "OriginalValue": "1",
      "Name": "PreInstalledAppsEverEnabled",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
      "OriginalValue": "1",
      "Name": "SilentInstalledAppsEnabled",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
      "OriginalValue": "1",
      "Name": "SubscribedContent-338387Enabled",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
      "OriginalValue": "1",
      "Name": "SubscribedContent-338388Enabled",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
      "OriginalValue": "1",
      "Name": "SubscribedContent-338389Enabled",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
      "OriginalValue": "1",
      "Name": "SubscribedContent-353698Enabled",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
      "OriginalValue": "1",
      "Name": "SystemPaneSuggestionsEnabled",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Microsoft\\Siuf\\Rules",
      "OriginalValue": "0",
      "Name": "NumberOfSIUFInPeriod",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection",
      "OriginalValue": "0",
      "Name": "DoNotShowFeedbackNotifications",
      "Value": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent",
      "OriginalValue": "0",
      "Name": "DisableTailoredExperiencesWithDiagnosticData",
      "Value": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\AdvertisingInfo",
      "OriginalValue": "0",
      "Name": "DisabledByGroupPolicy",
      "Value": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\Windows Error Reporting",
      "OriginalValue": "0",
      "Name": "Disabled",
      "Value": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\DeliveryOptimization\\Config",
      "OriginalValue": "1",
      "Name": "DODownloadMode",
      "Value": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Remote Assistance",
      "OriginalValue": "1",
      "Name": "fAllowToGetHelp",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\OperationStatusManager",
      "OriginalValue": "0",
      "Name": "EnthusiastMode",
      "Value": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "OriginalValue": "1",
      "Name": "ShowTaskViewButton",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\People",
      "OriginalValue": "1",
      "Name": "PeopleBand",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "OriginalValue": "1",
      "Name": "LaunchTo",
      "Value": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\FileSystem",
      "OriginalValue": "0",
      "Name": "LongPathsEnabled",
      "Value": "1",
      "Type": "DWord"
    },
    {
      "_Comment": "Driver searching is a function that should be left in",
      "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\DriverSearching",
      "OriginalValue": "1",
      "Name": "SearchOrderConfig",
      "Value": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile",
      "OriginalValue": "1",
      "Name": "SystemResponsiveness",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile",
      "OriginalValue": "1",
      "Name": "NetworkThrottlingIndex",
      "Value": "4294967295",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Control Panel\\Desktop",
      "OriginalValue": "1",
      "Name": "MenuShowDelay",
      "Value": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Control Panel\\Desktop",
      "OriginalValue": "1",
      "Name": "AutoEndTasks",
      "Value": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Memory Management",
      "OriginalValue": "0",
      "Name": "ClearPageFileAtShutdown",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKLM:\\SYSTEM\\ControlSet001\\Services\\Ndu",
      "OriginalValue": "1",
      "Name": "Start",
      "Value": "2",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Control Panel\\Mouse",
      "OriginalValue": "400",
      "Name": "MouseHoverTime",
      "Value": "400",
      "Type": "String"
    },
    {
      "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\LanmanServer\\Parameters",
      "OriginalValue": "20",
      "Name": "IRPStackSize",
      "Value": "30",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Windows Feeds",
      "OriginalValue": "1",
      "Name": "EnableFeeds",
      "Value": "0",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Feeds",
      "OriginalValue": "1",
      "Name": "ShellFeedsTaskbarViewMode",
      "Value": "2",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer",
      "OriginalValue": "1",
      "Name": "HideSCAMeetNow",
      "Value": "1",
      "Type": "DWord"
    },
    {
      "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\UserProfileEngagement",
      "OriginalValue": "1",
      "Name": "ScoobeSystemSettingEnabled",
      "Value": "0",
      "Type": "DWord"
    }
  ],
  "InvokeScript": [
    "
      bcdedit /set `{current`} bootmenupolicy Legacy | Out-Null
        If ((get-ItemProperty -Path \"HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\" -Name CurrentBuild).CurrentBuild -lt 22557) {
            $taskmgr = Start-Process -WindowStyle Hidden -FilePath taskmgr.exe -PassThru
            Do {
                Start-Sleep -Milliseconds 100
                $preferences = Get-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\TaskManager\" -Name \"Preferences\" -ErrorAction SilentlyContinue
            } Until ($preferences)
            Stop-Process $taskmgr
            $preferences.Preferences[28] = 0
            Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\TaskManager\" -Name \"Preferences\" -Type Binary -Value $preferences.Preferences
        }
        Remove-Item -Path \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace\\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}\" -Recurse -ErrorAction SilentlyContinue

        # Fix Managed by your organization in Edge if regustry path exists then remove it

        If (Test-Path \"HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge\") {
            Remove-Item -Path \"HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge\" -Recurse -ErrorAction SilentlyContinue
        }

        # Group svchost.exe processes
        $ram = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1kb
        Set-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\" -Name \"SvcHostSplitThresholdInKB\" -Type DWord -Value $ram -Force

        $autoLoggerDir = \"$env:PROGRAMDATA\\Microsoft\\Diagnosis\\ETLLogs\\AutoLogger\"
        If (Test-Path \"$autoLoggerDir\\AutoLogger-Diagtrack-Listener.etl\") {
            Remove-Item \"$autoLoggerDir\\AutoLogger-Diagtrack-Listener.etl\"
        }
        icacls $autoLoggerDir /deny SYSTEM:`(OI`)`(CI`)F | Out-Null

        # Disable Defender Auto Sample Submission
        Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue | Out-Null
        "
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Essential-Tweaks/Tele"
}
```

</details>

## 调用脚本

```powershell

      bcdedit /set `{current`} bootmenupolicy Legacy | Out-Null
        If ((get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild).CurrentBuild -lt 22557) {
            $taskmgr = Start-Process -WindowStyle Hidden -FilePath taskmgr.exe -PassThru
            Do {
                Start-Sleep -Milliseconds 100
                $preferences = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -ErrorAction SilentlyContinue
            } Until ($preferences)
            Stop-Process $taskmgr
            $preferences.Preferences[28] = 0
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\TaskManager" -Name "Preferences" -Type Binary -Value $preferences.Preferences
        }
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" -Recurse -ErrorAction SilentlyContinue

        # 如果注册表路径存在，则修复 Edge 中的“由您的组织管理”
        If (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge") {
            Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Recurse -ErrorAction SilentlyContinue
        }

        # 分组 svchost.exe 进程
        $ram = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1kb
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Type DWord -Value $ram -Force

        $autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
        If (Test-Path "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl") {
            Remove-Item "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl"
        }
        icacls $autoLoggerDir /deny SYSTEM:`(OI`)`(CI`)F | Out-Null

        # 禁用 Defender 自动示例提交
        Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue | Out-Null


```
## 注册表更改
应用程序和系统组件存储和检索配置数据以修改 Windows 设置，因此我们可以使用注册表在一个位置更改许多设置。


您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/windows/win32/sysinfo/registry)上找到有关注册表的信息。

### 注册表项：AllowTelemetry

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：AllowTelemetry

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：ContentDeliveryAllowed

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：OemPreInstalledAppsEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：PreInstalledAppsEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：PreInstalledAppsEverEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：SilentInstalledAppsEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：SubscribedContent-338387Enabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：SubscribedContent-338388Enabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：SubscribedContent-338389Enabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：SubscribedContent-353698Enabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：SystemPaneSuggestionsEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：NumberOfSIUFInPeriod

**类型：** DWord

**原始值：** 0

**新值：** 0

### 注册表项：DoNotShowFeedbackNotifications

**类型：** DWord

**原始值：** 0

**新值：** 1

### 注册表项：DisableTailoredExperiencesWithDiagnosticData

**类型：** DWord

**原始值：** 0

**新值：** 1

### 注册表项：DisabledByGroupPolicy

**类型：** DWord

**原始值：** 0

**新值：** 1

### 注册表项：Disabled

**类型：** DWord

**原始值：** 0

**新值：** 1

### 注册表项：DODownloadMode

**类型：** DWord

**原始值：** 1

**新值：** 1

### 注册表项：fAllowToGetHelp

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：EnthusiastMode

**类型：** DWord

**原始值：** 0

**新值：** 1

### 注册表项：ShowTaskViewButton

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：PeopleBand

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：LaunchTo

**类型：** DWord

**原始值：** 1

**新值：** 1

### 注册表项：LongPathsEnabled

**类型：** DWord

**原始值：** 0

**新值：** 1

### 注册表项：SearchOrderConfig

**类型：** DWord

**原始值：** 1

**新值：** 1

### 注册表项：SystemResponsiveness

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：NetworkThrottlingIndex

**类型：** DWord

**原始值：** 1

**新值：** 4294967295

### 注册表项：MenuShowDelay

**类型：** DWord

**原始值：** 1

**新值：** 1

### 注册表项：AutoEndTasks

**类型：** DWord

**原始值：** 1

**新值：** 1

### 注册表项：ClearPageFileAtShutdown

**类型：** DWord

**原始值：** 0

**新值：** 0

### 注册表项：Start

**类型：** DWord

**原始值：** 1

**新值：** 2

### 注册表项：MouseHoverTime

**类型：** String

**原始值：** 400

**新值：** 400

### 注册表项：IRPStackSize

**类型：** DWord

**原始值：** 20

**新值：** 30

### 注册表项：EnableFeeds

**类型：** DWord

**原始值：** 1

**新值：** 0

### 注册表项：ShellFeedsTaskbarViewMode

**类型：** DWord

**原始值：** 1

**新值：** 2

### 注册表项：HideSCAMeetNow

**类型：** DWord

**原始值：** 1

**新值：** 1

### 注册表项：ScoobeSystemSettingEnabled

**类型：** DWord

**原始值：** 1

**新值：** 0


## 计划任务更改

Windows 计划任务用于在特定时间或事件运行脚本或程序。禁用不必要的任务可以提高系统性能并减少不必要的后台活动。


您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_Task_Scheduler) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/windows/desktop/taskschd/about-the-task-scheduler)上找到有关计划任务的信息。

### 任务名称：Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser

**状态：** 已禁用

**原始状态：** 已启用

### 任务名称：Microsoft\Windows\Application Experience\ProgramDataUpdater

**状态：** 已禁用

**原始状态：** 已启用

### 任务名称：Microsoft\Windows\Autochk\Proxy

**状态：** 已禁用

**原始状态：** 已启用

### 任务名称：Microsoft\Windows\Customer Experience Improvement Program\Consolidator

**状态：** 已禁用

**原始状态：** 已启用

### 任务名称：Microsoft\Windows\Customer Experience Improvement Program\UsbCeip

**状态：** 已禁用

**原始状态：** 已启用

### 任务名称：Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector

**状态：** 已禁用

**原始状态：** 已启用

### 任务名称：Microsoft\Windows\Feedback\Siuf\DmClient

**状态：** 已禁用

**原始状态：** 已启用

### 任务名称：Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload

**状态：** 已禁用

**原始状态：** 已启用

### 任务名称：Microsoft\Windows\Windows Error Reporting\QueueReporting

**状态：** 已禁用

**原始状态：** 已启用

### 任务名称：Microsoft\Windows\Application Experience\MareBackup

**状态：** 已禁用

**原始状态：** 已启用

### 任务名称：Microsoft\Windows\Application Experience\StartupAppTask

**状态：** 已禁用

**原始状态：** 已启用

### 任务名称：Microsoft\Windows\Application Experience\PcaPatchDbTask

**状态：** 已禁用

**原始状态：** 已启用

### 任务名称：Microsoft\Windows\Maps\MapsUpdateTask

**状态：** 已禁用

**原始状态：** 已启用



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
