# Enable Daily Registry Backup Task 12.30am

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Enables daily registry backup, previously disabled by Microsoft in Windows 10 1803.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Enable Daily Registry Backup Task 12.30am",
  "Description": "Enables daily registry backup, previously disabled by Microsoft in Windows 10 1803.",
  "category": "Features",
  "panel": "1",
  "Order": "a017_",
  "feature": [],
  "InvokeScript": [
    "
      New-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager' -Name 'EnablePeriodicBackup' -Type DWord -Value 1 -Force
      New-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager' -Name 'BackupCount' -Type DWord -Value 2 -Force
      $action = New-ScheduledTaskAction -Execute 'schtasks' -Argument '/run /i /tn \"\\Microsoft\\Windows\\Registry\\RegIdleBackup\"'
      $trigger = New-ScheduledTaskTrigger -Daily -At 00:30
      Register-ScheduledTask -Action $action -Trigger $trigger -TaskName 'AutoRegBackup' -Description 'Create System Registry Backups' -User 'System'
      "
  ],
  "link": "https://christitustech.github.io/Winutil/dev/features/Features/RegBackup"
}
```

</details>

## Invoke Script

```powershell

      New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager' -Name 'EnablePeriodicBackup' -Type DWord -Value 1 -Force
      New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager' -Name 'BackupCount' -Type DWord -Value 2 -Force
      $action = New-ScheduledTaskAction -Execute 'schtasks' -Argument '/run /i /tn "\Microsoft\Windows\Registry\RegIdleBackup"'
      $trigger = New-ScheduledTaskTrigger -Daily -At 00:30
      Register-ScheduledTask -Action $action -Trigger $trigger -TaskName 'AutoRegBackup' -Description 'Create System Registry Backups' -User 'System'


```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/feature.json)

