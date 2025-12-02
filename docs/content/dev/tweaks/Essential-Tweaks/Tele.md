# Disable Telemetry

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Disables Microsoft Telemetry. Note: This will lock many Edge Browser settings. Microsoft spies heavily on you when using the Edge browser.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

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
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/Tele"
}
```

</details>

## Invoke Script

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

        # Fix Managed by your organization in Edge if regustry path exists then remove it

        If (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge") {
            Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Recurse -ErrorAction SilentlyContinue
        }

        # Group svchost.exe processes
        $ram = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1kb
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "SvcHostSplitThresholdInKB" -Type DWord -Value $ram -Force

        $autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
        If (Test-Path "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl") {
            Remove-Item "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl"
        }
        icacls $autoLoggerDir /deny SYSTEM:`(OI`)`(CI`)F | Out-Null

        # Disable Defender Auto Sample Submission
        Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue | Out-Null


```
## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.


You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).

### Registry Key: AllowTelemetry

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: AllowTelemetry

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: ContentDeliveryAllowed

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: OemPreInstalledAppsEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: PreInstalledAppsEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: PreInstalledAppsEverEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: SilentInstalledAppsEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: SubscribedContent-338387Enabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: SubscribedContent-338388Enabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: SubscribedContent-338389Enabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: SubscribedContent-353698Enabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: SystemPaneSuggestionsEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: NumberOfSIUFInPeriod

**Type:** DWord

**Original Value:** 0

**New Value:** 0

### Registry Key: DoNotShowFeedbackNotifications

**Type:** DWord

**Original Value:** 0

**New Value:** 1

### Registry Key: DisableTailoredExperiencesWithDiagnosticData

**Type:** DWord

**Original Value:** 0

**New Value:** 1

### Registry Key: DisabledByGroupPolicy

**Type:** DWord

**Original Value:** 0

**New Value:** 1

### Registry Key: Disabled

**Type:** DWord

**Original Value:** 0

**New Value:** 1

### Registry Key: DODownloadMode

**Type:** DWord

**Original Value:** 1

**New Value:** 1

### Registry Key: fAllowToGetHelp

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: EnthusiastMode

**Type:** DWord

**Original Value:** 0

**New Value:** 1

### Registry Key: ShowTaskViewButton

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: PeopleBand

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: LaunchTo

**Type:** DWord

**Original Value:** 1

**New Value:** 1

### Registry Key: LongPathsEnabled

**Type:** DWord

**Original Value:** 0

**New Value:** 1

### Registry Key: SearchOrderConfig

**Type:** DWord

**Original Value:** 1

**New Value:** 1

### Registry Key: SystemResponsiveness

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: NetworkThrottlingIndex

**Type:** DWord

**Original Value:** 1

**New Value:** 4294967295

### Registry Key: MenuShowDelay

**Type:** DWord

**Original Value:** 1

**New Value:** 1

### Registry Key: AutoEndTasks

**Type:** DWord

**Original Value:** 1

**New Value:** 1

### Registry Key: ClearPageFileAtShutdown

**Type:** DWord

**Original Value:** 0

**New Value:** 0

### Registry Key: Start

**Type:** DWord

**Original Value:** 1

**New Value:** 2

### Registry Key: MouseHoverTime

**Type:** String

**Original Value:** 400

**New Value:** 400

### Registry Key: IRPStackSize

**Type:** DWord

**Original Value:** 20

**New Value:** 30

### Registry Key: EnableFeeds

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: ShellFeedsTaskbarViewMode

**Type:** DWord

**Original Value:** 1

**New Value:** 2

### Registry Key: HideSCAMeetNow

**Type:** DWord

**Original Value:** 1

**New Value:** 1

### Registry Key: ScoobeSystemSettingEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0


## Scheduled Task Changes

Windows scheduled tasks are used to run scripts or programs at specific times or events. Disabling unnecessary tasks can improve system performance and reduce unwanted background activity.


You can find information about scheduled tasks on [Wikipedia](https://www.wikiwand.com/en/Windows_Task_Scheduler) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/desktop/taskschd/about-the-task-scheduler).

### Task Name: Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser

**State:** Disabled

**Original State:** Enabled

### Task Name: Microsoft\Windows\Application Experience\ProgramDataUpdater

**State:** Disabled

**Original State:** Enabled

### Task Name: Microsoft\Windows\Autochk\Proxy

**State:** Disabled

**Original State:** Enabled

### Task Name: Microsoft\Windows\Customer Experience Improvement Program\Consolidator

**State:** Disabled

**Original State:** Enabled

### Task Name: Microsoft\Windows\Customer Experience Improvement Program\UsbCeip

**State:** Disabled

**Original State:** Enabled

### Task Name: Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector

**State:** Disabled

**Original State:** Enabled

### Task Name: Microsoft\Windows\Feedback\Siuf\DmClient

**State:** Disabled

**Original State:** Enabled

### Task Name: Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload

**State:** Disabled

**Original State:** Enabled

### Task Name: Microsoft\Windows\Windows Error Reporting\QueueReporting

**State:** Disabled

**Original State:** Enabled

### Task Name: Microsoft\Windows\Application Experience\MareBackup

**State:** Disabled

**Original State:** Enabled

### Task Name: Microsoft\Windows\Application Experience\StartupAppTask

**State:** Disabled

**Original State:** Enabled

### Task Name: Microsoft\Windows\Application Experience\PcaPatchDbTask

**State:** Disabled

**Original State:** Enabled

### Task Name: Microsoft\Windows\Maps\MapsUpdateTask

**State:** Disabled

**Original State:** Enabled



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

