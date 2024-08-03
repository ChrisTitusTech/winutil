# Enable Daily Registry Backup Task 12.30am

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Enables daily registry backup, previously disabled by Microsoft in Windows 10 1803.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Enable Daily Registry Backup Task 12.30am",
    "Description":  "Enables daily registry backup, previously disabled by Microsoft in Windows 10 1803.",
    "link":  "https://christitustech.github.io/winutil/dev/features/Legacy-Windows-Panels/user",
    "category":  "Features",
    "panel":  "1",
    "Order":  "a017_",
    "feature":  [

                ],
    "InvokeScript":  [
                         "\r\n      New-ItemProperty -Path \u0027HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager\u0027 -Name \u0027EnablePeriodicBackup\u0027 -Type DWord -Value 1 -Force\r\n      New-ItemProperty -Path \u0027HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Configuration Manager\u0027 -Name \u0027BackupCount\u0027 -Type DWord -Value 2 -Force\r\n      $action = New-ScheduledTaskAction -Execute \u0027schtasks\u0027 -Argument \u0027/run /i /tn \"\\Microsoft\\Windows\\Registry\\RegIdleBackup\"\u0027\r\n      $trigger = New-ScheduledTaskTrigger -Daily -At 00:30\r\n      Register-ScheduledTask -Action $action -Trigger $trigger -TaskName \u0027AutoRegBackup\u0027 -Description \u0027Create System Registry Backups\u0027 -User \u0027System\u0027\r\n      "
                     ]
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

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)

