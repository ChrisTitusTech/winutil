# Adobe Debloat

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Manages Adobe Services, Adobe Desktop Service, and Acrobat Updates

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Adobe Debloat",
  "Description": "Manages Adobe Services, Adobe Desktop Service, and Acrobat Updates",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a021_",
  "InvokeScript": [
    "
      function CCStopper {
        $path = \"C:\\Program Files (x86)\\Common Files\\Adobe\\Adobe Desktop Common\\ADS\\Adobe Desktop Service.exe\"

        # Test if the path exists before proceeding
        if (Test-Path $path) {
            Takeown /f $path
            $acl = Get-Acl $path
            $acl.SetOwner([System.Security.Principal.NTAccount]\"Administrators\")
            $acl | Set-Acl $path

            Rename-Item -Path $path -NewName \"Adobe Desktop Service.exe.old\" -Force
        } else {
            Write-Host \"Adobe Desktop Service is not in the default location.\"
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

        $rootPath = \"HKLM:\\SOFTWARE\\WOW6432Node\\Adobe\\Adobe ARM\\Legacy\\Acrobat\"

        # Get all subkeys under the specified root path
        $subKeys = Get-ChildItem -Path $rootPath | Where-Object { $_.PSChildName -like \"{*}\" }

        # Loop through each subkey
        foreach ($subKey in $subKeys) {
            # Get the full registry path
            $fullPath = Join-Path -Path $rootPath -ChildPath $subKey.PSChildName
            try {
                Set-ItemProperty -Path $fullPath -Name Mode -Value 0
                Write-Host \"Acrobat Updates have been disabled.\"
            } catch {
                Write-Host \"Registry Key for changing Acrobat Updates does not exist in $fullPath\"
            }
        }
      }

      CCStopper
      AcrobatUpdates
      "
  ],
  "UndoScript": [
    "
      function RestoreCCService {
        $originalPath = \"C:\\Program Files (x86)\\Common Files\\Adobe\\Adobe Desktop Common\\ADS\\Adobe Desktop Service.exe.old\"
        $newPath = \"C:\\Program Files (x86)\\Common Files\\Adobe\\Adobe Desktop Common\\ADS\\Adobe Desktop Service.exe\"

        if (Test-Path -Path $originalPath) {
            Rename-Item -Path $originalPath -NewName \"Adobe Desktop Service.exe\" -Force
            Write-Host \"Adobe Desktop Service has been restored.\"
        } else {
            Write-Host \"Backup file does not exist. No changes were made.\"
        }
      }

      function AcrobatUpdates {
        # Default Value:
        # 3 = Automatically download and install updates

        $rootPath = \"HKLM:\\SOFTWARE\\WOW6432Node\\Adobe\\Adobe ARM\\Legacy\\Acrobat\"

        # Get all subkeys under the specified root path
        $subKeys = Get-ChildItem -Path $rootPath | Where-Object { $_.PSChildName -like \"{*}\" }

        # Loop through each subkey
        foreach ($subKey in $subKeys) {
            # Get the full registry path
            $fullPath = Join-Path -Path $rootPath -ChildPath $subKey.PSChildName
            try {
                Set-ItemProperty -Path $fullPath -Name Mode -Value 3
            } catch {
                Write-Host \"Registry Key for changing Acrobat Updates does not exist in $fullPath\"
            }
        }
      }

      RestoreCCService
      AcrobatUpdates
      "
  ],
  "service": [
    {
      "Name": "AGSService",
      "StartupType": "Disabled",
      "OriginalType": "Automatic"
    },
    {
      "Name": "AGMService",
      "StartupType": "Disabled",
      "OriginalType": "Automatic"
    },
    {
      "Name": "AdobeUpdateService",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "Adobe Acrobat Update",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "Adobe Genuine Monitor Service",
      "StartupType": "Disabled",
      "OriginalType": "Automatic"
    },
    {
      "Name": "AdobeARMservice",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "Adobe Licensing Console",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "CCXProcess",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "AdobeIPCBroker",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "CoreSync",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    }
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/DebloatAdobe"
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


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

