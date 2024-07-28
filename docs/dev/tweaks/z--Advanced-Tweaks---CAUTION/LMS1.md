﻿# Disable Intel MM (vPro LMS)


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Intel LMS service is always listening on all ports and could be a huge security risk. There is no need to run LMS on home machines and even in the Enterprise there are better solutions.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Disable Intel MM (vPro LMS)",
    "Description":  "Intel LMS service is always listening on all ports and could be a huge security risk. There is no need to run LMS on home machines and even in the Enterprise there are better solutions.",
    "category":  "z__Advanced Tweaks - CAUTION",
    "panel":  "1",
    "Order":  "a026_",
    "InvokeScript":  [
                         "\r\n        Write-Host \"Kill LMS\"\r\n        $serviceName = \"LMS\"\r\n        Write-Host \"Stopping and disabling service: $serviceName\"\r\n        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue;\r\n        Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue;\r\n\r\n        Write-Host \"Removing service: $serviceName\";\r\n        sc.exe delete $serviceName;\r\n\r\n        Write-Host \"Removing LMS driver packages\";\r\n        $lmsDriverPackages = Get-ChildItem -Path \"C:\\Windows\\System32\\DriverStore\\FileRepository\" -Recurse -Filter \"lms.inf*\";\r\n        foreach ($package in $lmsDriverPackages) {\r\n            Write-Host \"Removing driver package: $($package.Name)\";\r\n            pnputil /delete-driver $($package.Name) /uninstall /force;\r\n        }\r\n        if ($lmsDriverPackages.Count -eq 0) {\r\n            Write-Host \"No LMS driver packages found in the driver store.\";\r\n        } else {\r\n            Write-Host \"All found LMS driver packages have been removed.\";\r\n        }\r\n\r\n        Write-Host \"Searching and deleting LMS executable files\";\r\n        $programFilesDirs = @(\"C:\\Program Files\", \"C:\\Program Files (x86)\");\r\n        $lmsFiles = @();\r\n        foreach ($dir in $programFilesDirs) {\r\n            $lmsFiles += Get-ChildItem -Path $dir -Recurse -Filter \"LMS.exe\" -ErrorAction SilentlyContinue;\r\n        }\r\n        foreach ($file in $lmsFiles) {\r\n            Write-Host \"Taking ownership of file: $($file.FullName)\";\r\n            \u0026 icacls $($file.FullName) /grant Administrators:F /T /C /Q;\r\n            \u0026 takeown /F $($file.FullName) /A /R /D Y;\r\n            Write-Host \"Deleting file: $($file.FullName)\";\r\n            Remove-Item $($file.FullName) -Force -ErrorAction SilentlyContinue;\r\n        }\r\n        if ($lmsFiles.Count -eq 0) {\r\n            Write-Host \"No LMS.exe files found in Program Files directories.\";\r\n        } else {\r\n            Write-Host \"All found LMS.exe files have been deleted.\";\r\n        }\r\n        Write-Host \u0027Intel LMS vPro service has been disabled, removed, and blocked.\u0027;\r\n       "
                     ],
    "UndoScript":  [
                       "\r\n      Write-Host \"LMS vPro needs to be redownloaded from intel.com\"\r\n\r\n      "
                   ]
}
```
</details>

## Invoke Script

```json

        Write-Host "Kill LMS"
        $serviceName = "LMS"
        Write-Host "Stopping and disabling service: $serviceName"
        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue;
        Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue;

        Write-Host "Removing service: $serviceName";
        sc.exe delete $serviceName;

        Write-Host "Removing LMS driver packages";
        $lmsDriverPackages = Get-ChildItem -Path "C:\Windows\System32\DriverStore\FileRepository" -Recurse -Filter "lms.inf*";
        foreach ($package in $lmsDriverPackages) {
            Write-Host "Removing driver package: $($package.Name)";
            pnputil /delete-driver $($package.Name) /uninstall /force;
        }
        if ($lmsDriverPackages.Count -eq 0) {
            Write-Host "No LMS driver packages found in the driver store.";
        } else {
            Write-Host "All found LMS driver packages have been removed.";
        }

        Write-Host "Searching and deleting LMS executable files";
        $programFilesDirs = @("C:\Program Files", "C:\Program Files (x86)");
        $lmsFiles = @();
        foreach ($dir in $programFilesDirs) {
            $lmsFiles += Get-ChildItem -Path $dir -Recurse -Filter "LMS.exe" -ErrorAction SilentlyContinue;
        }
        foreach ($file in $lmsFiles) {
            Write-Host "Taking ownership of file: $($file.FullName)";
            & icacls $($file.FullName) /grant Administrators:F /T /C /Q;
            & takeown /F $($file.FullName) /A /R /D Y;
            Write-Host "Deleting file: $($file.FullName)";
            Remove-Item $($file.FullName) -Force -ErrorAction SilentlyContinue;
        }
        if ($lmsFiles.Count -eq 0) {
            Write-Host "No LMS.exe files found in Program Files directories.";
        } else {
            Write-Host "All found LMS.exe files have been deleted.";
        }
        Write-Host 'Intel LMS vPro service has been disabled, removed, and blocked.';
       

```
## Undo Script

```json

      Write-Host "LMS vPro needs to be redownloaded from intel.com"

      

```
<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
