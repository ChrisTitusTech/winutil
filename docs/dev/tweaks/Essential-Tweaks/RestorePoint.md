# Create Restore Point

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Creates a restore point at runtime in case a revert is needed from WinUtil modifications

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Create Restore Point",
    "Description":  "Creates a restore point at runtime in case a revert is needed from WinUtil modifications",
    "link":  "https://christitustech.github.io/winutil/dev/tweaks/Shortcuts/Shortcut",
    "category":  "Essential Tweaks",
    "panel":  "1",
    "Checked":  "False",
    "Order":  "a001_",
    "InvokeScript":  [
                         "\r\n        # Check if the user has administrative privileges\r\n        if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {\r\n            Write-Host \"Please run this script as an administrator.\"\r\n            return\r\n        }\r\n\r\n        # Check if System Restore is enabled for the main drive\r\n        try {\r\n            # Try getting restore points to check if System Restore is enabled\r\n            Enable-ComputerRestore -Drive \"$env:SystemDrive\"\r\n        } catch {\r\n            Write-Host \"An error occurred while enabling System Restore: $_\"\r\n        }\r\n\r\n        # Check if the SystemRestorePointCreationFrequency value exists\r\n        $exists = Get-ItemProperty -path \"HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\SystemRestore\" -Name \"SystemRestorePointCreationFrequency\" -ErrorAction SilentlyContinue\r\n        if($null -eq $exists){\r\n            write-host \u0027Changing system to allow multiple restore points per day\u0027\r\n            Set-ItemProperty -Path \"HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\SystemRestore\" -Name \"SystemRestorePointCreationFrequency\" -Value \"0\" -Type DWord -Force -ErrorAction Stop | Out-Null\r\n        }\r\n\r\n        # Attempt to load the required module for Get-ComputerRestorePoint\r\n        try {\r\n            Import-Module Microsoft.PowerShell.Management -ErrorAction Stop\r\n        } catch {\r\n            Write-Host \"Failed to load the Microsoft.PowerShell.Management module: $_\"\r\n            return\r\n        }\r\n\r\n        # Get all the restore points for the current day\r\n        try {\r\n            $existingRestorePoints = Get-ComputerRestorePoint | Where-Object { $_.CreationTime.Date -eq (Get-Date).Date }\r\n        } catch {\r\n            Write-Host \"Failed to retrieve restore points: $_\"\r\n            return\r\n        }\r\n\r\n        # Check if there is already a restore point created today\r\n        if ($existingRestorePoints.Count -eq 0) {\r\n            $description = \"System Restore Point created by WinUtil\"\r\n\r\n            Checkpoint-Computer -Description $description -RestorePointType \"MODIFY_SETTINGS\"\r\n            Write-Host -ForegroundColor Green \"System Restore Point Created Successfully\"\r\n        }\r\n      "
                     ]
}
```
</details>

## Invoke Script

```powershell

        # Check if the user has administrative privileges
        if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Host "Please run this script as an administrator."
            return
        }

        # Check if System Restore is enabled for the main drive
        try {
            # Try getting restore points to check if System Restore is enabled
            Enable-ComputerRestore -Drive "$env:SystemDrive"
        } catch {
            Write-Host "An error occurred while enabling System Restore: $_"
        }

        # Check if the SystemRestorePointCreationFrequency value exists
        $exists = Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -ErrorAction SilentlyContinue
        if($null -eq $exists){
            write-host 'Changing system to allow multiple restore points per day'
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -Value "0" -Type DWord -Force -ErrorAction Stop | Out-Null
        }

        # Attempt to load the required module for Get-ComputerRestorePoint
        try {
            Import-Module Microsoft.PowerShell.Management -ErrorAction Stop
        } catch {
            Write-Host "Failed to load the Microsoft.PowerShell.Management module: $_"
            return
        }

        # Get all the restore points for the current day
        try {
            $existingRestorePoints = Get-ComputerRestorePoint | Where-Object { $_.CreationTime.Date -eq (Get-Date).Date }
        } catch {
            Write-Host "Failed to retrieve restore points: $_"
            return
        }

        # Check if there is already a restore point created today
        if ($existingRestorePoints.Count -eq 0) {
            $description = "System Restore Point created by WinUtil"

            Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS"
            Write-Host -ForegroundColor Green "System Restore Point Created Successfully"
        }
      

```
<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

