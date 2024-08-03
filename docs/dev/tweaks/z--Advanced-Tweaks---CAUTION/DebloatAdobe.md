# Adobe Debloat

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Manages Adobe Services, Adobe Desktop Service, and Acrobat Updates

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Adobe Debloat",
    "Description":  "Manages Adobe Services, Adobe Desktop Service, and Acrobat Updates",
    "link":  "https://christitustech.github.io/winutil/dev/tweaks/Shortcuts/Shortcut",
    "category":  "z__Advanced Tweaks - CAUTION",
    "panel":  "1",
    "Order":  "a021_",
    "InvokeScript":  [
                         "\r\n      function CCStopper {\r\n        $path = \"C:\\Program Files (x86)\\Common Files\\Adobe\\Adobe Desktop Common\\ADS\\Adobe Desktop Service.exe\"\r\n\r\n        # Test if the path exists before proceeding\r\n        if (Test-Path $path) {\r\n            Takeown /f $path\r\n            $acl = Get-Acl $path\r\n            $acl.SetOwner([System.Security.Principal.NTAccount]\"Administrators\")\r\n            $acl | Set-Acl $path\r\n\r\n            Rename-Item -Path $path -NewName \"Adobe Desktop Service.exe.old\" -Force\r\n        } else {\r\n            Write-Host \"Adobe Desktop Service is not in the default location.\"\r\n        }\r\n      }\r\n\r\n\r\n      function AcrobatUpdates {\r\n        # Editing Acrobat Updates. The last folder before the key is dynamic, therefore using a script.\r\n        # Possible Values for the edited key:\r\n        # 0 = Do not download or install updates automatically\r\n        # 2 = Automatically download updates but let the user choose when to install them\r\n        # 3 = Automatically download and install updates (default value)\r\n        # 4 = Notify the user when an update is available but don\u0027t download or install it automatically\r\n        #   = It notifies the user using Windows Notifications. It runs on startup without having to have a Service/Acrobat/Reader running, therefore 0 is the next best thing.\r\n\r\n        $rootPath = \"HKLM:\\SOFTWARE\\WOW6432Node\\Adobe\\Adobe ARM\\Legacy\\Acrobat\"\r\n\r\n        # Get all subkeys under the specified root path\r\n        $subKeys = Get-ChildItem -Path $rootPath | Where-Object { $_.PSChildName -like \"{*}\" }\r\n\r\n        # Loop through each subkey\r\n        foreach ($subKey in $subKeys) {\r\n            # Get the full registry path\r\n            $fullPath = Join-Path -Path $rootPath -ChildPath $subKey.PSChildName\r\n            try {\r\n                Set-ItemProperty -Path $fullPath -Name Mode -Value 0\r\n                Write-Host \"Acrobat Updates have been disabled.\"\r\n            } catch {\r\n                Write-Host \"Registry Key for changing Acrobat Updates does not exist in $fullPath\"\r\n            }\r\n        }\r\n      }\r\n\r\n      CCStopper\r\n      AcrobatUpdates\r\n      "
                     ],
    "UndoScript":  [
                       "\r\n      function RestoreCCService {\r\n        $originalPath = \"C:\\Program Files (x86)\\Common Files\\Adobe\\Adobe Desktop Common\\ADS\\Adobe Desktop Service.exe.old\"\r\n        $newPath = \"C:\\Program Files (x86)\\Common Files\\Adobe\\Adobe Desktop Common\\ADS\\Adobe Desktop Service.exe\"\r\n\r\n        if (Test-Path -Path $originalPath) {\r\n            Rename-Item -Path $originalPath -NewName \"Adobe Desktop Service.exe\" -Force\r\n            Write-Host \"Adobe Desktop Service has been restored.\"\r\n        } else {\r\n            Write-Host \"Backup file does not exist. No changes were made.\"\r\n        }\r\n      }\r\n\r\n      function AcrobatUpdates {\r\n        # Default Value:\r\n        # 3 = Automatically download and install updates\r\n\r\n        $rootPath = \"HKLM:\\SOFTWARE\\WOW6432Node\\Adobe\\Adobe ARM\\Legacy\\Acrobat\"\r\n\r\n        # Get all subkeys under the specified root path\r\n        $subKeys = Get-ChildItem -Path $rootPath | Where-Object { $_.PSChildName -like \"{*}\" }\r\n\r\n        # Loop through each subkey\r\n        foreach ($subKey in $subKeys) {\r\n            # Get the full registry path\r\n            $fullPath = Join-Path -Path $rootPath -ChildPath $subKey.PSChildName\r\n            try {\r\n                Set-ItemProperty -Path $fullPath -Name Mode -Value 3\r\n            } catch {\r\n                Write-Host \"Registry Key for changing Acrobat Updates does not exist in $fullPath\"\r\n            }\r\n        }\r\n      }\r\n\r\n      RestoreCCService\r\n      AcrobatUpdates\r\n      "
                   ],
    "service":  [
                    {
                        "Name":  "AGSService",
                        "StartupType":  "Disabled",
                        "OriginalType":  "Automatic"
                    },
                    {
                        "Name":  "AGMService",
                        "StartupType":  "Disabled",
                        "OriginalType":  "Automatic"
                    },
                    {
                        "Name":  "AdobeUpdateService",
                        "StartupType":  "Manual",
                        "OriginalType":  "Automatic"
                    },
                    {
                        "Name":  "Adobe Acrobat Update",
                        "StartupType":  "Manual",
                        "OriginalType":  "Automatic"
                    },
                    {
                        "Name":  "Adobe Genuine Monitor Service",
                        "StartupType":  "Disabled",
                        "OriginalType":  "Automatic"
                    },
                    {
                        "Name":  "AdobeARMservice",
                        "StartupType":  "Manual",
                        "OriginalType":  "Automatic"
                    },
                    {
                        "Name":  "Adobe Licensing Console",
                        "StartupType":  "Manual",
                        "OriginalType":  "Automatic"
                    },
                    {
                        "Name":  "CCXProcess",
                        "StartupType":  "Manual",
                        "OriginalType":  "Automatic"
                    },
                    {
                        "Name":  "AdobeIPCBroker",
                        "StartupType":  "Manual",
                        "OriginalType":  "Automatic"
                    },
                    {
                        "Name":  "CoreSync",
                        "StartupType":  "Manual",
                        "OriginalType":  "Automatic"
                    }
                ]
}
```
</details>

## Invoke Script

```powershell

      function CCStopper {
        $path = "C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\ADS\Adobe Desktop Service.exe"

        # Test if the path exists before proceeding
        if (Test-Path $path) {
            Takeown /f $path
            $acl = Get-Acl $path
            $acl.SetOwner([System.Security.Principal.NTAccount]"Administrators")
            $acl | Set-Acl $path

            Rename-Item -Path $path -NewName "Adobe Desktop Service.exe.old" -Force
        } else {
            Write-Host "Adobe Desktop Service is not in the default location."
        }
      }


      function AcrobatUpdates {
        # Editing Acrobat Updates. The last folder before the key is dynamic, therefore using a script.
        # Possible Values for the edited key:
        # 0 = Do not download or install updates automatically
        # 2 = Automatically download updates but let the user choose when to install them
        # 3 = Automatically download and install updates (default value)
        # 4 = Notify the user when an update is available but don't download or install it automatically
        #   = It notifies the user using Windows Notifications. It runs on startup without having to have a Service/Acrobat/Reader running, therefore 0 is the next best thing.

        $rootPath = "HKLM:\SOFTWARE\WOW6432Node\Adobe\Adobe ARM\Legacy\Acrobat"

        # Get all subkeys under the specified root path
        $subKeys = Get-ChildItem -Path $rootPath | Where-Object { $_.PSChildName -like "{*}" }

        # Loop through each subkey
        foreach ($subKey in $subKeys) {
            # Get the full registry path
            $fullPath = Join-Path -Path $rootPath -ChildPath $subKey.PSChildName
            try {
                Set-ItemProperty -Path $fullPath -Name Mode -Value 0
                Write-Host "Acrobat Updates have been disabled."
            } catch {
                Write-Host "Registry Key for changing Acrobat Updates does not exist in $fullPath"
            }
        }
      }

      CCStopper
      AcrobatUpdates
      

```
## Undo Script

```powershell

      function RestoreCCService {
        $originalPath = "C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\ADS\Adobe Desktop Service.exe.old"
        $newPath = "C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\ADS\Adobe Desktop Service.exe"

        if (Test-Path -Path $originalPath) {
            Rename-Item -Path $originalPath -NewName "Adobe Desktop Service.exe" -Force
            Write-Host "Adobe Desktop Service has been restored."
        } else {
            Write-Host "Backup file does not exist. No changes were made."
        }
      }

      function AcrobatUpdates {
        # Default Value:
        # 3 = Automatically download and install updates

        $rootPath = "HKLM:\SOFTWARE\WOW6432Node\Adobe\Adobe ARM\Legacy\Acrobat"

        # Get all subkeys under the specified root path
        $subKeys = Get-ChildItem -Path $rootPath | Where-Object { $_.PSChildName -like "{*}" }

        # Loop through each subkey
        foreach ($subKey in $subKeys) {
            # Get the full registry path
            $fullPath = Join-Path -Path $rootPath -ChildPath $subKey.PSChildName
            try {
                Set-ItemProperty -Path $fullPath -Name Mode -Value 3
            } catch {
                Write-Host "Registry Key for changing Acrobat Updates does not exist in $fullPath"
            }
        }
      }

      RestoreCCService
      AcrobatUpdates
      

```
## Service Changes
Windows services are background processes for system functions or applications. Setting some to manual optimizes performance by starting them only when needed.

You can find information about services on [Wikipedia](https://www.wikiwand.com/en/Windows_service) and [Microsoft's Website](https://learn.microsoft.com/en-us/dotnet/framework/windows-services/introduction-to-windows-service-applications).
### Service Name: AGSService
**Startup Type:** Disabled

**Original Type:** Automatic

### Service Name: AGMService
**Startup Type:** Disabled

**Original Type:** Automatic

### Service Name: AdobeUpdateService
**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: Adobe Acrobat Update
**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: Adobe Genuine Monitor Service
**Startup Type:** Disabled

**Original Type:** Automatic

### Service Name: AdobeARMservice
**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: Adobe Licensing Console
**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: CCXProcess
**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: AdobeIPCBroker
**Startup Type:** Manual

**Original Type:** Automatic

### Service Name: CoreSync
**Startup Type:** Manual

**Original Type:** Automatic


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

