# Disable Telemetry


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a bit part of the dev-docs stays up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


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
    "\r\n      bcdedit /set `{current`} bootmenupolicy Legacy | Out-Null\r\n        If ((get-ItemProperty -Path \"HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\" -Name CurrentBuild).CurrentBuild -lt 22557) {\r\n            $taskmgr = Start-Process -WindowStyle Hidden -FilePath taskmgr.exe -PassThru\r\n            Do {\r\n                Start-Sleep -Milliseconds 100\r\n                $preferences = Get-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\TaskManager\" -Name \"Preferences\" -ErrorAction SilentlyContinue\r\n            } Until ($preferences)\r\n            Stop-Process $taskmgr\r\n            $preferences.Preferences[28] = 0\r\n            Set-ItemProperty -Path \"HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\TaskManager\" -Name \"Preferences\" -Type Binary -Value $preferences.Preferences\r\n        }\r\n        Remove-Item -Path \"HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace\\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}\" -Recurse -ErrorAction SilentlyContinue\r\n\r\n        # Fix Managed by your organization in Edge if regustry path exists then remove it\r\n\r\n        If (Test-Path \"HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge\") {\r\n            Remove-Item -Path \"HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge\" -Recurse -ErrorAction SilentlyContinue\r\n        }\r\n\r\n        # Group svchost.exe processes\r\n        $ram = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1kb\r\n        Set-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\" -Name \"SvcHostSplitThresholdInKB\" -Type DWord -Value $ram -Force\r\n\r\n        $autoLoggerDir = \"$env:PROGRAMDATA\\Microsoft\\Diagnosis\\ETLLogs\\AutoLogger\"\r\n        If (Test-Path \"$autoLoggerDir\\AutoLogger-Diagtrack-Listener.etl\") {\r\n            Remove-Item \"$autoLoggerDir\\AutoLogger-Diagtrack-Listener.etl\"\r\n        }\r\n        icacls $autoLoggerDir /deny SYSTEM:`(OI`)`(CI`)F | Out-Null\r\n\r\n        # Disable Defender Auto Sample Submission\r\n        Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue | Out-Null\r\n        "
  ]
}
```
</details>

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
### Walkthrough.
#### Registry Key: AllowTelemetry
**Path:** HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: AllowTelemetry
**Path:** HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: ContentDeliveryAllowed
**Path:** HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: OemPreInstalledAppsEnabled
**Path:** HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: PreInstalledAppsEnabled
**Path:** HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: PreInstalledAppsEverEnabled
**Path:** HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: SilentInstalledAppsEnabled
**Path:** HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: SubscribedContent-338387Enabled
**Path:** HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: SubscribedContent-338388Enabled
**Path:** HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: SubscribedContent-338389Enabled
**Path:** HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: SubscribedContent-353698Enabled
**Path:** HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: SystemPaneSuggestionsEnabled
**Path:** HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: NumberOfSIUFInPeriod
**Path:** HKCU:\SOFTWARE\Microsoft\Siuf\Rules

**Type:** DWord

**Original Value:** 0

**New Value:** 0

#### Registry Key: DoNotShowFeedbackNotifications
**Path:** HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection

**Type:** DWord

**Original Value:** 0

**New Value:** 1

#### Registry Key: DisableTailoredExperiencesWithDiagnosticData
**Path:** HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent

**Type:** DWord

**Original Value:** 0

**New Value:** 1

#### Registry Key: DisabledByGroupPolicy
**Path:** HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo

**Type:** DWord

**Original Value:** 0

**New Value:** 1

#### Registry Key: Disabled
**Path:** HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting

**Type:** DWord

**Original Value:** 0

**New Value:** 1

#### Registry Key: DODownloadMode
**Path:** HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config

**Type:** DWord

**Original Value:** 1

**New Value:** 1

#### Registry Key: fAllowToGetHelp
**Path:** HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: EnthusiastMode
**Path:** HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager

**Type:** DWord

**Original Value:** 0

**New Value:** 1

#### Registry Key: ShowTaskViewButton
**Path:** HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: PeopleBand
**Path:** HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: LaunchTo
**Path:** HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced

**Type:** DWord

**Original Value:** 1

**New Value:** 1

#### Registry Key: LongPathsEnabled
**Path:** HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem

**Type:** DWord

**Original Value:** 0

**New Value:** 1

#### Registry Key: SearchOrderConfig
**Path:** HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching

**Type:** DWord

**Original Value:** 1

**New Value:** 1

#### Registry Key: SystemResponsiveness
**Path:** HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: NetworkThrottlingIndex
**Path:** HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile

**Type:** DWord

**Original Value:** 1

**New Value:** 4294967295

#### Registry Key: MenuShowDelay
**Path:** HKCU:\Control Panel\Desktop

**Type:** DWord

**Original Value:** 1

**New Value:** 1

#### Registry Key: AutoEndTasks
**Path:** HKCU:\Control Panel\Desktop

**Type:** DWord

**Original Value:** 1

**New Value:** 1

#### Registry Key: ClearPageFileAtShutdown
**Path:** HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management

**Type:** DWord

**Original Value:** 0

**New Value:** 0

#### Registry Key: Start
**Path:** HKLM:\SYSTEM\ControlSet001\Services\Ndu

**Type:** DWord

**Original Value:** 1

**New Value:** 2

#### Registry Key: MouseHoverTime
**Path:** HKCU:\Control Panel\Mouse

**Type:** String

**Original Value:** 400

**New Value:** 400

#### Registry Key: IRPStackSize
**Path:** HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters

**Type:** DWord

**Original Value:** 20

**New Value:** 30

#### Registry Key: EnableFeeds
**Path:** HKCU:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds

**Type:** DWord

**Original Value:** 1

**New Value:** 0

#### Registry Key: ShellFeedsTaskbarViewMode
**Path:** HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds

**Type:** DWord

**Original Value:** 1

**New Value:** 2

#### Registry Key: HideSCAMeetNow
**Path:** HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer

**Type:** DWord

**Original Value:** 1

**New Value:** 1

#### Registry Key: ScoobeSystemSettingEnabled
**Path:** HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement

**Type:** DWord

**Original Value:** 1

**New Value:** 0



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

