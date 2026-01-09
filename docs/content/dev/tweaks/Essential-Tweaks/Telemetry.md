# Disable Telemetry

```json
"WPFTweaksTelemetry": {
    "Content": "Disable Telemetry",
    "Description": "Disables Microsoft Telemetry...Duh",
    "category": "Essential Tweaks",
    "panel": "1",
    "Order": "a003_",
    "ScheduledTask": [
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
      }
    ],
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\DataCollection",
        "OriginalValue": "<RemoveEntry>",
        "Name": "AllowTelemetry",
        "Value": "0",
        "Type": "DWord"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DataCollection",
        "OriginalValue": "<RemoveEntry>",
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
        "OriginalValue": "<RemoveEntry>",
        "Name": "DoNotShowFeedbackNotifications",
        "Value": "1",
        "Type": "DWord"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent",
        "OriginalValue": "<RemoveEntry>",
        "Name": "DisableTailoredExperiencesWithDiagnosticData",
        "Value": "1",
        "Type": "DWord"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\AdvertisingInfo",
        "OriginalValue": "<RemoveEntry>",
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
        "Value": "0",
        "Type": "DWord"
      },
      {
        "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\DeliveryOptimization",
        "OriginalValue": "<RemoveEntry>",
        "Name": "DODownloadMode",
        "Value": "0",
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
        "Path": "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\LanmanServer\\Parameters",
        "OriginalValue": "20",
        "Name": "IRPStackSize",
        "Value": "30",
        "Type": "DWord"
      },
      {
        "Path": "HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Windows Feeds",
        "OriginalValue": "<RemoveEntry>",
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
        "OriginalValue": "<RemoveEntry>",
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
      # Disable Defender Auto Sample Submission
      Set-MpPreference -SubmitSamplesConsent 2
      "
    ],
```
