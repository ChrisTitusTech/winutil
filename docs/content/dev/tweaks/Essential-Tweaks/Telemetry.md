# Disable Telemetry

```json
  "WPFTweaksTelemetry": {
    "Content": "Disable Telemetry",
    "Description": "Disables Microsoft Telemetry...Duh",
    "category": "Essential Tweaks",
    "panel": "1",
    "Order": "a003_",
    "registry": [
      {
        "Path": "HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\DataCollection",
        "Name": "AllowTelemetry",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "<RemoveEntry>"
      },
      {
        "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "Name": "ContentDeliveryAllowed",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "1"
      },
      {
        "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "Name": "SubscribedContent-338389Enabled",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "1"
      },
      {
        "Path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\ContentDeliveryManager",
        "Name": "SubscribedContent-338387Enabled",
        "Value": "0",
        "Type": "DWord",
        "OriginalValue": "1"
      }
    ],
    "InvokeScript": [
      "
      # Disable Defender Auto Sample Submission
      Set-MpPreference -SubmitSamplesConsent 2

      # Disable (Connected User Experiences and Telemetry) Service
      Set-Service -Name diagtrack -StartupType Disabled

      # Disable (Windows Error Reporting Manager) Service
      Set-Service -Name wermgr -StartupType Disabled
      
      $Memory = (Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1KB
      Set-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\" -Name SvcHostSplitThresholdInKB -Value $Memory
      "
    ],
    "UndoScript": [
      "
      # Enable Defender Auto Sample Submission
      Set-MpPreference -SubmitSamplesConsent 1

      # Enable (Connected User Experiences and Telemetry) Service
      Set-Service -Name diagtrack -StartupType Automatic

      # Enable (Windows Error Reporting Manager) Service
      Set-Service -Name wermgr -StartupType Automatic
      "
    ],
```

## Registry Changes

Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.

You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).
