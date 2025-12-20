function Microwin-NewReportingTool {

    # embedding reporting tool with here string
    $reportingTool = @'
    function Get-ComputerInventory {
    <#
        .SYNOPSIS
            Gets and stores computer inventory related to system hardware and software.
        .OUTPUTS
            The reported computer inventory.
    #>

    # hinv variable name makes reference to ARCS-based SGI systems and hinv command
    $hinv = "---- HARDWARE INVENTORY:"

    # first we get all hardware inventory possible: CPU, memory, disks, BIOS, computer system...
    $computerSystemInformation = Get-CimInstance Win32_ComputerSystem
    $processorInformation = Get-CimInstance Win32_Processor
    $memoryInformation = Get-CimInstance Win32_PhysicalMemory
    $volumeInformation = Get-Volume | Where-Object { $_.DriveType -eq "Fixed" }
    $biosInformation = Get-CimInstance Win32_BIOS

    $hinv += "`n`n-- Computer System:`n"

    # Computer System information reported:
    # - Manufacturer
    # - Model
    # - System Family
    # - System SKU Number
    # - Hypervisor Present
    $hinv += "`n    - Manufacturer: $($computerSystemInformation.Manufacturer)"
    $hinv += "`n    - Model: $($computerSystemInformation.Model)"
    $hinv += "`n    - System Family: $($computerSystemInformation.SystemFamily)"
    $hinv += "`n    - System SKU Number: $($computerSystemInformation.SystemSKUNumber)"
    $hinv += "`n    - Hypervisor Present? $($computerSystemInformation.HypervisorPresent)"

    $hinv += "`n`n-- Processor:`n"

    # Processor information reported, for each processor:
    # - Device ID
    #     - Name
    #     - Manufacturer
    #     - Caption
    #    - Number of Cores (of which Number of Enabled Cores)
    #     - Number of Total Logical processors
    $processorInformation | Foreach-Object {
        $hinv += "`nFor device ID $($_.DeviceID):"
        $hinv += "`n    - Name: $($_.Name)"
        $hinv += "`n    - Manufacturer: $($_.Manufacturer)"
        $hinv += "`n    - Caption: $($_.Caption)"
        $hinv += "`n    - Number of Cores: $($_.NumberOfCores), of which $($_.NumberOfEnabledCore) are enabled"
        $hinv += "`n    - Number of Total Logical Processors: $($_.NumberOfLogicalProcessors)"
    }

    $hinv += "`n`n-- Memory information:`n"

    # Memory information reported, for each module:
    # - Module number
    #     - Bank Label
    #     - Tag
    #     - Manufacturer -- this is the reference provided by manufacturer. For example, HMCG88AGBSA092N returns a SK Hynix module
    #     - Part Number
    #     - Clock Speed
    $moduleNumber = 0
    $memoryInformation | Foreach-Object {
        $hinv += "`nModule number $($moduleNumber):"
        $hinv += "`n    - Bank Label: $($_.BankLabel)"
        $hinv += "`n    - Tag: $($_.Tag)"
        $hinv += "`n    - Manufacturer: $($_.Manufacturer)"
        $hinv += "`n    - Part Number: $($_.PartNumber)"
        $hinv += "`n    - Clock Speed: $($_.Speed) MT/s"
        $moduleNumber++
    }

    $hinv += "`n`n-- Available Volumes as of reporting tool run time:`n"

    # Disk Volume information reported, for each volume:
    # - Drive UniqueID
    #     - Drive Letter
    #     - Drive Label
    #     - Drive Type
    #     - File System type
    #     - Health Status
    #     - Total Size
    #     - Remaining Size (Size Percentage)
    $volumeInformation | Foreach-Object {
        $hinv += "`nFor volume with UniqueID $($_.UniqueId):"
        $hinv += "`n    - Drive Letter: $($_.DriveLetter)"
        $hinv += "`n    - Drive Label: $($_.FriendlyName)"
        $hinv += "`n    - Drive Type: $($_.DriveType)"
        $hinv += "`n    - File System: $($_.FileSystemType)"
        $hinv += "`n    - Health: $($_.HealthStatus)"
        $hinv += "`n    - Size: $([Math]::Round($_.Size / 1GB, 2)) GB"
        $hinv += "`n    - Size Remaining: $([Math]::Round($_.SizeRemaining / 1GB, 2)) GB. Percentage: $([Math]::Round((($_.SizeRemaining / $_.Size) * 100), 2))%"
    }

    $hinv += "`n`n-- BIOS information:`n"

    # BIOS information:
    # - Manufacturer
    # - Name
    # - Caption
    # - BIOS version
    # - Serial Number
    $hinv += "`n    - Manufacturer: $($biosInformation.Manufacturer)"
    $hinv += "`n    - Name: $($biosInformation.Name)"
    $hinv += "`n    - Caption: $($biosInformation.Caption)"
    $hinv += "`n    - Version: $($biosInformation.SMBIOSBIOSVersion)"
    $hinv += "`n    - Serial Number: $($biosInformation.SerialNumber)"

    $sinv = "---- SOFTWARE INVENTORY:`n"

    $computerInformation = Get-ComputerInfo

    $sinv += "`n$($computerInformation.OsName). Version: $($computerInformation.OsVersion). Version Display Name: $($computerInformation.OSDisplayVersion). Build String: $($computerInformation.WindowsBuildLabEx)"
    $sinv += "`nBuild Type: $($computerInformation.OsBuildType)"
    $sinv += "`nEdition ID: $($computerInformation.WindowsEditionId)"
    $sinv += "`nInstalled Hotfixes:"

    $computerInformation.OsHotFixes | Foreach-Object {
        $sinv += "`n    - $($_.HotFixID): $($_.Description). Installed on $($_.InstalledOn)"
    }

    $sinv += "`nEnvironment Variables:"
    Get-ChildItem "ENV:" | ForEach-Object {
        $sinv += "`n    - $($_.Name): $($_.Value)"
    }

    # this information is recorded by winutil when it creates the ISO
    if (Test-Path "HKLM:\SOFTWARE\WinUtil") {
        $sinv += "`nMicroWin installation medium information:"
        $sinv += "`n    - Created with WinUtil version: $(Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\WinUtil" -Name "ToolboxVersion")"
        $sinv += "`n    - Build Date: $(Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\WinUtil" -Name "MicroWinBuildDate")"
    }

    $inv = "$($hinv)`n`n$($sinv)"

    return $inv
}

function Get-ImageInventory {
    $imageInv = "---- IMAGE INFORMATION:`n"
    Write-Host "Getting operating system packages..."

    $imageInv += "`n-- Operating System Packages:`n"

    try {
        $packageInformation = Get-WindowsPackage -Online
        $imageInv += "`nPackage Count: $($packageInformation.Count)`n"
        $packageInformation | ForEach-Object {
            $imageInv += "`n- Package $($_.PackageName):"
            $imageInv += "`n    - State: $($_.PackageState)"
            $imageInv += "`n    - Release Type: $($_.ReleaseType)"
            $imageInv += "`n    - Installation Time: $($_.InstallTime)"
        }
    } catch {
        $imageInv += "`nCould not get package information."
    }

    Write-Host "Getting operating system features..."

    $imageInv += "`n`n-- Operating System Features:`n"

    try {
        $featureInformation = Get-WindowsOptionalFeature -Online
        $imageInv += "`nFeature Count: $($featureInformation.Count)`n"
        $featureInformation | ForEach-Object {
            $imageInv += "`n- Feature $($_.FeatureName):"
            $imageInv += "`n    - State: $($_.State)"
        }
    } catch {
        $imageInv += "`nCould not get feature information."
    }

    Write-Host "Getting operating system AppX packages for all users..."

    $imageInv += "`n`n-- Operating System AppX packages:`n"

    try {
        $appxPackageInformation = Get-AppxPackage -AllUsers
        $imageInv += "`nAppX Package Count: $($appxPackageInformation.Count)`n"
        $appxPackageInformation | ForEach-Object {
            $imageInv += "`n- Package $($_.PackageFullName):"
            $imageInv += "`n    - Name: $($_.Name)"
            $imageInv += "`n    - Publisher: $($_.Publisher)"
            $imageInv += "`n    - Architecture: $($_.Architecture)"
            $imageInv += "`n    - Resource ID: $($_.ResourceId)"
            $imageInv += "`n    - Version: $($_.Version)"
            $imageInv += "`n    - Installation Location: $($_.InstallLocation)"
            $imageInv += "`n    - Is a framework? $($_.IsFramework)"
            $imageInv += "`n    - Package Family Name: $($_.PackageFamilyName)"
            $imageInv += "`n    - Publisher ID: $($_.PublisherId)"
            $imageInv += "`n    - User Information: $($_.PackageUserInformation | Foreach-Object {
    @(
        "`n        - For SID: $($_.UserSecurityId.Sid):"
        "`n            - Name: $($_.UserSecurityId.Username.Replace("$env:USERNAME", "<Your user>"))"
        "`n            - State: $($_.InstallState)"
    )

})"
            $imageInv += "`n    - Is a resource package?: $($_.IsResourcePackage)"
            $imageInv += "`n    - Is a bundle? $($_.IsBundle)"
            $imageInv += "`n    - Is in development mode? $($_.IsDevelopmentMode)"
            $imageInv += "`n    - Is non removable? $($_.NonRemovable)"
            $imageInv += "`n    - Dependencies: $($_.Dependencies)"
            $imageInv += "`n    - Is partially staged? $($_.IsPartiallyStaged)"
            $imageInv += "`n    - Signature kind: $($_.SignatureKind)"
            $imageInv += "`n    - Status: $($_.Status)"
        }
    } catch {
        $imageInv += "`nCould not get AppX package information."
    }

    Write-Host "Getting operating system capabilities..."

    $imageInv += "`n`n-- Operating System Capabilities:`n"

    try {
        $capabilityInformation = Get-WindowsCapability -Online
        $imageInv += "`nCapability Count: $($capabilityInformation.Count)`n"
        $capabilityInformation | ForEach-Object {
            $imageInv += "`n- Capability $($_.Name):"
            $imageInv += "`n    - State: $($_.State)"
        }
    } catch {
        $imageInv += "`nCould not get capability information."
    }

    Write-Host "Getting operating system drivers (1st and 3rd party)..."

    $imageInv += "`n`n-- Operating System Drivers:`n"

    try {
        $driverInformation = Get-WindowsDriver -All -Online
        $imageInv += "`nDriver Count: $($driverInformation.Count)`n"
        $driverInformation | ForEach-Object {
            $imageInv += "`n- Driver $($_.Driver):"
            $imageInv += "`n    - Original File Name: $($_.OriginalFileName)"
            $imageInv += "`n    - Is Inbox Driver? $($_.Inbox)"
            $imageInv += "`n    - Class Name: $($_.ClassName)"
            $imageInv += "`n    - Is critical to the boot process? $($_.BootCritical)"
            $imageInv += "`n    - Provider Name: $($_.ProviderName)"
            $imageInv += "`n    - Date: $($_.Date)"
            $imageInv += "`n    - Version: $($_.Version)"
        }
    } catch {
        $imageInv += "`nCould not get driver information."
    }

    return $imageInv
}

function Prepare-SetupLogs {
    param (
        [Parameter(Mandatory = $true, Position = 0)] [string]$pantherLogsPath
    )

    if ((Test-Path "$pantherLogsPath") -eq $false) {
        try {
            New-Item -ItemType Directory -Path "$pantherLogsPath" | Out-Null
        } catch {
            Write-Host "Logs folder could not be created."
            return
        }
    }

    # we copy the Panther logs to our report tool folder
    Write-Host "Copying Panther setup logs..."
    Copy-Item -Path "$env:SYSTEMROOT\Panther\setupact.log" -Destination "$pantherLogsPath\setupact.log" -Force -Verbose -ErrorAction SilentlyContinue
    Copy-Item -Path "$env:SYSTEMROOT\Panther\setuperr.log" -Destination "$pantherLogsPath\setuperr.log" -Force -Verbose -ErrorAction SilentlyContinue

    Compress-Report -itemToCompress "$pantherLogsPath\setup*.log" -destinationZip "$pantherLogsPath\setuplogs.zip"
    if ($?) { Remove-Item -Path "$pantherLogsPath\setup*.log" -Recurse -Force -Verbose }

    # we copy the ETL so we can later convert it to EVTX
    Write-Host "Copying Panther event logs..."
    Copy-Item -Path "$env:SYSTEMROOT\Panther\setup.etl" -Destination "$pantherLogsPath\setup.etl" -Force -Verbose -ErrorAction SilentlyContinue

    # now we convert the ETL to EVTX -- i guess no one knows about tracerpt, neither did I...
    # we'll keep the original ETL just in case tracerpt fails
    Write-Host "Converting setup.etl..."
    tracerpt "$pantherLogsPath\setup.etl" -o "$pantherLogsPath\setup.evtx" -of EVTX -y -lr

    # if we failed to create the EVTX out of the ETL, at least include a way to convert it manually
    "tracerpt `".\setup.etl`" -o `".\setup.evtx`" -of EVTX -y -lr" | Out-File -Force -Encoding UTF8 -FilePath "$pantherLogsPath\convertEtl.bat"
}

function Prepare-CBSLogs {
    param (
        [Parameter(Mandatory = $true, Position = 0)] [string]$cbsLogsPath
    )

    if ((Test-Path "$env:SYSTEMROOT\Logs\CBS") -eq $false) {
        Write-Host "CBS logs folder not found on system. Not doing anything"
        return
    }

    if ((Test-Path "$cbsLogsPath") -eq $false) {
        try {
            New-Item -ItemType Directory -Path "$cbsLogsPath" | Out-Null
        } catch {
            Write-Host "Logs folder could not be created."
            return
        }
    }

    # we copy the CBS logs
    Write-Host "Copying CBS logs..."
    Copy-Item -Path "$env:SYSTEMROOT\Logs\CBS\CBS.log" -Destination "$cbsLogsPath\cbs.log" -Force -Verbose -ErrorAction SilentlyContinue
}

function Prepare-DismLogs {
    param (
        [Parameter(Mandatory = $true, Position = 0)] [string]$dismLogsPath
    )

    if ((Test-Path "$env:SYSTEMROOT\Logs\DISM") -eq $false) {
        Write-Host "DISM logs folder not found on system. Not doing anything"
        return
    }

    if ((Test-Path "$dismLogsPath") -eq $false) {
        try {
            New-Item -ItemType Directory -Path "$dismLogsPath" | Out-Null
        } catch {
            Write-Host "Logs folder could not be created."
            return
        }
    }

    # we copy the DISM logs
    Write-Host "Copying DISM logs..."
    Copy-Item -Path "$env:SYSTEMROOT\Logs\DISM\dism.log" -Destination "$dismLogsPath\dism.log" -Force -Verbose -ErrorAction SilentlyContinue
    Compress-Report -itemToCompress "$dismLogsPath\dism.log" -Destination "$dismLogsPath\dismLog.zip"
    if ($?) { Remove-Item -Path "$dismLogsPath\dism.log" -Force -Verbose }
}

function Compress-Report {
    param (
        [Parameter(Mandatory = $true, Position = 0)] [string]$itemToCompress,
        [Parameter(Mandatory = $true, Position = 1)] [string]$destinationZip
    )

    try {
        Compress-Archive -Path "$itemToCompress" -DestinationPath "$destinationZip" -Force
    } catch {
        Write-Host "ZIP file could not be created..."
    }
}

$version = "1.0"

Write-Host "MicroWin reporting tool -- version $version"
Write-Host "-------------------------------------------"
Write-Host "Saving system information to a report file. The report file will be saved to your desktop. This will take some time..."

$mwReportToolPath = "$env:USERPROFILE\Desktop\MWReportToolFiles"

# first some computer inventory
New-Item -ItemType Directory -Path "$mwReportToolPath" -Force | Out-Null
Get-ComputerInventory | Out-File -Force -Encoding UTF8 -FilePath "$mwReportToolPath\computerReport.txt"
Get-ImageInventory | Out-File -Force -Encoding UTF8 -FilePath "$mwReportToolPath\imageReport.txt"

# next some setup logs
New-Item -ItemType Directory -Path "$mwReportToolPath\PantherSetup" -Force | Out-Null
New-Item -ItemType Directory -Path "$mwReportToolPath\ComponentBasedServicing" -Force | Out-Null
New-Item -ItemType Directory -Path "$mwReportToolPath\DISM" -Force | Out-Null
Prepare-SetupLogs -pantherLogsPath "$mwReportToolPath\PantherSetup"
Prepare-CBSLogs -cbsLogsPath "$mwReportToolPath\ComponentBasedServicing"
Prepare-DismLogs -dismLogsPath "$mwReportToolPath\DISM"

# finally we pack everything
"This file contains reporting information that can be used to help us diagnose issues," | Out-File -Force -Encoding UTF8 -FilePath "$mwReportToolPath\README.txt"
"if you run into any. It is safe to delete this file if you don't want it, but we" | Out-File -Append -Encoding UTF8 -FilePath "$mwReportToolPath\README.txt"
"recommend that you move it instead. (You might need this at any time). If it exceeds" | Out-File -Append -Encoding UTF8 -FilePath "$mwReportToolPath\README.txt"
"GitHub's maximum size limit, you can try recompressing the ZIP file with 7-Zip and a" | Out-File -Append -Encoding UTF8 -FilePath "$mwReportToolPath\README.txt"
"higher compression level or removing the biggest files in there.`n" | Out-File -Append -Encoding UTF8 -FilePath "$mwReportToolPath\README.txt"
"The Reporting Tool was made by CodingWonders (https://github.com/CodingWonders) for" | Out-File -Append -Encoding UTF8 -FilePath "$mwReportToolPath\README.txt"
"the purpose of it being useful." | Out-File -Append -Encoding UTF8 -FilePath "$mwReportToolPath\README.txt"
Write-Host "Preparing report ZIP file..."
Compress-Report -itemToCompress "$mwReportToolPath" -destinationZip "$mwReportToolPath\..\MicroWinReportTool_$((Get-Date).ToString('yyMMdd-HHmm')).zip"
Remove-Item -Path "$mwReportToolPath" -Recurse
'@

    $reportingTool | Out-File -FilePath "$env:TEMP\reportTool.ps1" -Force
}
