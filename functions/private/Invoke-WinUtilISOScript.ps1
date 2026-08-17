function Invoke-WinUtilISOScript {
    <#
    .SYNOPSIS
        Prepares copied Windows setup media without modifying its install image.

    .DESCRIPTION
        Stages WinUtil's AppX removal, registry tweaks, and scheduled-task cleanup
        in the answer file for first logon, writes sources\ei.cfg for the selected
        edition, and optionally adds current-system drivers to one install.wim index.

    .PARAMETER ISOContentsDir
        Root directory of the copied ISO contents.

    .PARAMETER AutoUnattendXml
        Full XML content for autounattend.xml.

    .PARAMETER InstallEditionId
        Windows setup EditionID for sources\ei.cfg, for example Professional or Core.

    .PARAMETER InstallImagePath
        Copied install.wim to service when current-system driver injection is enabled.

    .PARAMETER InstallImageIndex
        Selected edition index in install.wim.

    .PARAMETER Log
        Optional ScriptBlock for progress/status logging. Receives a single [string] argument.
    #>
    param (
        [Parameter(Mandatory)][string]$ISOContentsDir,
        [string]$AutoUnattendXml = "",
        [bool]$InjectCurrentSystemDrivers = $false,
        [string]$InstallEditionId = "",
        [string]$InstallImagePath = "",
        [int]$InstallImageIndex = 1,
        [scriptblock]$Log = { param($m) Write-Output $m }
    )

    function Format-WinUtilISOElapsed {
        param ([Parameter(Mandatory)][System.Diagnostics.Stopwatch]$Stopwatch)

        return $Stopwatch.Elapsed.ToString('hh\:mm\:ss\.fff')
    }

    function Get-WinUtilISODriverPackageInventory {
        param (
            [Parameter(Mandatory)][AllowEmptyCollection()][System.IO.FileInfo[]]$DriverInfs,
            [scriptblock]$Logger
        )

        $packages = @($DriverInfs | Group-Object { $_.Directory.FullName } | ForEach-Object {
            [pscustomobject]@{
                Directory = [string]$_.Name
                InfNames  = @($_.Group | ForEach-Object Name)
            }
        })

        $null = & $Logger "Inventoried $($DriverInfs.Count) INF files across $($packages.Count) exported package directories."
        return $packages
    }

    function Get-WinUtilISOActiveStorageDriverMapping {
        param ([scriptblock]$Logger)

        try {
            $driverByDeviceId = @{}
            foreach ($driver in @(Get-CimInstance -ClassName Win32_PnPSignedDriver -ErrorAction Stop)) {
                if ($driver.DeviceID -and $driver.InfName) {
                    $driverByDeviceId[[string]$driver.DeviceID] = $driver
                }
            }

            $systemDrive = if ($env:SystemDrive) { $env:SystemDrive } else { 'C:' }
            $logicalDisk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$systemDrive'" -ErrorAction Stop
            if (-not $logicalDisk) {
                throw "The system volume '$systemDrive' was not found."
            }

            $partitions = @(Get-CimAssociatedInstance -InputObject $logicalDisk -Association Win32_LogicalDiskToPartition -ErrorAction Stop)
            if ($partitions.Count -eq 0) {
                throw "No partition was associated with system volume '$systemDrive'."
            }

            $systemDisks = @($partitions | ForEach-Object {
                Get-CimAssociatedInstance -InputObject $_ -Association Win32_DiskDriveToDiskPartition -ErrorAction Stop
            })
            $diskDeviceIds = @($systemDisks | Where-Object PNPDeviceID | ForEach-Object { [string]$_.PNPDeviceID } | Sort-Object -Unique)
            if ($diskDeviceIds.Count -ne 1) {
                throw "Expected one physical disk for system volume '$systemDrive', but found $($diskDeviceIds.Count)."
            }

            # Devices with Setup Class outside this set (chipset/platform "System" devices, ACPI,
            # generic PCI bridges, ...) are where WinPE driver staging stops climbing: they sit in
            # the disk's PnP ancestry but are not demonstrably needed to enumerate the disk/controller.
            $storageEnumerationDeviceClasses = @('DiskDrive', 'SCSIAdapter', 'HDC', 'USB', 'SDHost', 'PCMCIA')

            $publishedInfNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            $visitedDeviceIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            $deviceId = $diskDeviceIds[0]
            $maximumParentDepth = 64

            for ($depth = 0; $deviceId; $depth++) {
                if ($depth -ge $maximumParentDepth) {
                    throw "The PnP parent chain exceeded $maximumParentDepth devices starting at '$($diskDeviceIds[0])'."
                }
                if (-not $visitedDeviceIds.Add($deviceId)) {
                    throw "The PnP parent chain contains a cycle at '$deviceId'."
                }

                $driver = $driverByDeviceId[$deviceId]
                if ($depth -gt 0 -and (-not $driver -or [string]$driver.DeviceClass -notin $storageEnumerationDeviceClasses)) {
                    $null = & $Logger "Stopped at PnP ancestor '$deviceId' outside the storage-enumeration device classes."
                    break
                }

                if ($driver) {
                    [void]$publishedInfNames.Add([string]$driver.InfName)
                    $null = & $Logger "Active storage-path device '$deviceId' uses published INF '$($driver.InfName)' (class '$($driver.DeviceClass)')."
                }

                $parent = Get-PnpDeviceProperty -InstanceId $deviceId -KeyName 'DEVPKEY_Device_Parent' -ErrorAction Stop
                $deviceId = if ($parent.Data) { [string]$parent.Data } else { $null }
            }
            if ($publishedInfNames.Count -eq 0) {
                throw "No signed driver was mapped to the PnP chain starting at '$($diskDeviceIds[0])'."
            }
        } catch {
            throw "WinPE driver classification failed while discovering the active system-disk path: $_"
        }

        $activeOemInfNames = @($publishedInfNames | Where-Object { $_ -match '(?i)^oem\d+\.inf$' })
        $inboxInfNames = @($publishedInfNames | Where-Object { $_ -notmatch '(?i)^oem\d+\.inf$' })
        if ($inboxInfNames.Count -gt 0) {
            $null = & $Logger "Ignoring inbox INF names on the active storage path: $($inboxInfNames -join ', ')."
        }
        if ($activeOemInfNames.Count -eq 0) {
            $null = & $Logger 'Active storage-path discovery found no third-party OEM INF requiring WinPE staging.'
            return @()
        }

        $pnputilOutput = @(& pnputil.exe /enum-drivers /format csv 2>&1)
        $pnputilExitCode = $LASTEXITCODE
        if ($pnputilExitCode -ne 0) {
            throw "WinPE driver classification failed: PnPUtil driver inventory exited with code $pnputilExitCode."
        }

        $csvText = ($pnputilOutput | ForEach-Object { [string]$_ }) -join "`r`n"
        if ([string]::IsNullOrWhiteSpace($csvText)) {
            throw 'WinPE driver classification failed: PnPUtil returned empty CSV output.'
        }

        try {
            $driverInventory = @($csvText | ConvertFrom-Csv -ErrorAction Stop)
        } catch {
            throw "WinPE driver classification failed: PnPUtil CSV could not be parsed: $_"
        }
        if ($driverInventory.Count -eq 0) {
            throw 'WinPE driver classification failed: PnPUtil CSV contained no driver records.'
        }

        $inventoryProperties = @($driverInventory[0].PSObject.Properties.Name)
        if ('DriverName' -notin $inventoryProperties -or 'OriginalName' -notin $inventoryProperties) {
            throw 'WinPE driver classification failed: PnPUtil CSV is missing DriverName or OriginalName.'
        }
        foreach ($inventoryDriver in $driverInventory) {
            if ([string]::IsNullOrWhiteSpace([string]$inventoryDriver.DriverName) -or
                [string]::IsNullOrWhiteSpace([string]$inventoryDriver.OriginalName)) {
                throw 'WinPE driver classification failed: PnPUtil CSV contains an unusable DriverName or OriginalName value.'
            }
        }

        $activeMappings = [System.Collections.Generic.List[object]]::new()
        foreach ($publishedInfName in $activeOemInfNames) {
            $inventoryMatches = @($driverInventory | Where-Object { $_.DriverName -eq $publishedInfName })
            if ($inventoryMatches.Count -gt 1) {
                throw "WinPE driver classification failed: PnPUtil returned multiple records for published INF '$publishedInfName'."
            }
            if ($inventoryMatches.Count -eq 0) {
                throw "WinPE driver classification failed: PnPUtil did not translate published INF '$publishedInfName'."
            }

            $originalInfName = [string]$inventoryMatches[0].OriginalName
            $activeMappings.Add([pscustomobject]@{
                PublishedInfName = [string]$publishedInfName
                OriginalInfName  = $originalInfName
            })
            $null = & $Logger "Mapped active driver '$publishedInfName' to original INF '$originalInfName'."
        }

        return @($activeMappings)
    }

    function Select-WinUtilISOWinPEDriverPackage {
        param (
            [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Packages,
            [scriptblock]$Logger
        )

        $activeDrivers = @(Get-WinUtilISOActiveStorageDriverMapping -Logger $Logger)
        if ($activeDrivers.Count -eq 0) {
            return @()
        }

        $selectedDirectories = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($activeDriver in $activeDrivers) {
            $matchingPackages = @($Packages | Where-Object { $_.InfNames -contains $activeDriver.OriginalInfName })
            if ($matchingPackages.Count -eq 0) {
                throw "WinPE driver classification failed: active published INF '$($activeDriver.PublishedInfName)' maps to original INF '$($activeDriver.OriginalInfName)', but no exported package directory contains it."
            }
            if ($matchingPackages.Count -gt 1) {
                $directories = $matchingPackages.Directory -join "', '"
                throw "WinPE driver classification is ambiguous: active published INF '$($activeDriver.PublishedInfName)' maps to original INF '$($activeDriver.OriginalInfName)', which exists in multiple exported package directories: '$directories'."
            }

            [void]$selectedDirectories.Add([string]$matchingPackages[0].Directory)
        }

        $amdRaidInfNames = @('rcbottom.inf', 'rcraid.inf', 'rccfg.inf')
        $selectedPackages = @($Packages | Where-Object { $selectedDirectories.Contains([string]$_.Directory) })
        $selectedAmdRaidInfs = @($selectedPackages | ForEach-Object InfNames | Where-Object { $_ -in $amdRaidInfNames })
        if ($selectedAmdRaidInfs.Count -gt 0) {
            foreach ($amdRaidInfName in $amdRaidInfNames) {
                $matchingPackages = @($Packages | Where-Object { $_.InfNames -contains $amdRaidInfName })
                if ($matchingPackages.Count -eq 0) {
                    throw "WinPE driver classification failed: active AMD RAID package requires '$amdRaidInfName', but no exported package directory contains it."
                }
                if ($matchingPackages.Count -gt 1) {
                    $directories = $matchingPackages.Directory -join "', '"
                    throw "WinPE driver classification is ambiguous: AMD RAID dependency '$amdRaidInfName' exists in multiple exported package directories: '$directories'."
                }
                [void]$selectedDirectories.Add([string]$matchingPackages[0].Directory)
            }
        }

        $selectedPackages = @($Packages | Where-Object { $selectedDirectories.Contains([string]$_.Directory) })
        foreach ($package in $selectedPackages) {
            $null = & $Logger "Selected active WinPE driver package '$($package.Directory)'."
        }
        return $selectedPackages
    }

    function Copy-WinUtilISODriverPackage {
        param (
            [Parameter(Mandatory)][string]$Source,
            [Parameter(Mandatory)][string]$Destination
        )

        New-Item -Path $Destination -ItemType Directory -Force | Out-Null
        $folderName = Split-Path $Source -Leaf
        $targetPath = Join-Path $Destination $folderName
        $suffix = 1
        while (Test-Path -LiteralPath $targetPath) {
            $targetPath = Join-Path $Destination "${folderName}_$suffix"
            $suffix++
        }

        Copy-Item -LiteralPath $Source -Destination $targetPath -Recurse -Force -ErrorAction Stop
        return $targetPath
    }

    function Add-WinUtilISOStagedDrivers {
        param (
            [Parameter(Mandatory)][string]$ContentRoot,
            [Parameter(Mandatory)][string]$InstallImagePath,
            [Parameter(Mandatory)][int]$InstallImageIndex,
            [scriptblock]$Logger
        )

        function Invoke-WinUtilISODism {
            param (
                [Parameter(Mandatory)][string[]]$Arguments,
                [Parameter(Mandatory)][string]$Operation
            )

            $operationTimer = [System.Diagnostics.Stopwatch]::StartNew()
            $output = @(& dism.exe @Arguments 2>&1)
            $exitCode = $LASTEXITCODE
            $operationTimer.Stop()
            $elapsed = Format-WinUtilISOElapsed -Stopwatch $operationTimer
            if ($exitCode -ne 0) {
                foreach ($line in @($output | Select-Object -Last 20)) {
                    if (-not [string]::IsNullOrWhiteSpace([string]$line)) {
                        & $Logger "  dism[$Operation]: $line"
                    }
                }
                throw "DISM $Operation failed with exit code $exitCode after $elapsed."
            }
            if ($Operation -ne 'metadata') {
                $null = & $Logger "DISM $Operation completed in $elapsed."
            }
            return $output
        }

        function Get-WinUtilISOWimMetadata {
            param ([Parameter(Mandatory)][string]$ImagePath, [Parameter(Mandatory)][int]$Index)

            $metadata = @{}
            $output = Invoke-WinUtilISODism -Arguments @('/English', '/Get-WimInfo', "/WimFile:$ImagePath", "/Index:$Index") -Operation 'metadata'
            foreach ($line in $output) {
                if ([string]$line -match '^\s*([^:]+?)\s*:\s*(.*?)\s*$') {
                    $metadata[$Matches[1].Trim()] = $Matches[2].Trim()
                }
            }
            return $metadata
        }

        function Assert-WinUtilISOWimMetadata {
            param (
                [Parameter(Mandatory)][hashtable]$Before,
                [hashtable]$After
            )

            foreach ($key in 'Languages', 'Installation', 'Edition', 'ProductSuite', 'ProductType') {
                $beforeValue = [string]$Before[$key]
                if ($beforeValue -eq '<undefined>' -or ($key -in 'Installation', 'Edition', 'ProductType' -and [string]::IsNullOrWhiteSpace($beforeValue))) {
                    throw "install.wim metadata is already invalid: $key is undefined. Driver injection was not attempted."
                }
                if ($After) {
                    $afterValue = [string]$After[$key]
                    if ($afterValue -eq '<undefined>' -or ($beforeValue -and $afterValue -ne $beforeValue)) {
                        throw "install.wim metadata validation failed after driver injection: $key changed from '$beforeValue' to '$afterValue'."
                    }
                }
            }
        }

        function Test-WinUtilISOMountedImage {
            param ([Parameter(Mandatory)][string]$Path)

            return @(& dism.exe /English /Get-MountedImageInfo 2>$null) -match [regex]::Escape($Path)
        }

        if ([IO.Path]::GetExtension($InstallImagePath) -ne '.wim') {
            throw 'Current-system driver injection requires install.wim; install.esd cannot be serviced in place.'
        }
        if (-not (Test-Path -LiteralPath $InstallImagePath)) {
            throw "install.wim was not found: $InstallImagePath"
        }
        if ($InstallImageIndex -lt 1) {
            throw 'Current-system driver injection requires a valid install.wim image index.'
        }

        $driverExportRoot = Join-Path $env:TEMP "WinUtil_DriverExport_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(([guid]::NewGuid()).ToString('N').Substring(0, 8))"
        $mountDir = Join-Path (Split-Path -Path $ContentRoot -Parent) 'wim_mount'
        New-Item -Path $driverExportRoot -ItemType Directory -Force | Out-Null
        $imageMounted = $false

        try {
            & $Logger "Exporting current system drivers before modifying install.wim..."
            $dismLog = Join-Path $env:TEMP "WinUtil_DismDriverExport_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
            $driverExportTimer = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $dismProcess = Start-Process -FilePath "dism.exe" -ArgumentList "/online /export-driver /destination:`"$driverExportRoot`" /LogPath:`"$dismLog`"" -Wait -NoNewWindow -PassThru
            } catch {
                $driverExportTimer.Stop()
                throw "dism.exe driver export failed after $(Format-WinUtilISOElapsed -Stopwatch $driverExportTimer): $_"
            } finally {
                if ($driverExportTimer.IsRunning) {
                    $driverExportTimer.Stop()
                }
            }
            $driverExportElapsed = Format-WinUtilISOElapsed -Stopwatch $driverExportTimer
            if ($dismProcess.ExitCode -ne 0) {
                throw "dism.exe driver export failed with exit code $($dismProcess.ExitCode) after $driverExportElapsed."
            }
            $null = & $Logger "Driver export completed in $driverExportElapsed."

            $driverInfs = @(Get-ChildItem -LiteralPath $driverExportRoot -Filter '*.inf' -Recurse -File)
            if ($driverInfs.Count -eq 0) {
                throw 'DISM exported no driver INF files.'
            }

            $classificationTimer = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $driverPackages = @(Get-WinUtilISODriverPackageInventory -DriverInfs $driverInfs -Logger $Logger)
                $winpeDriverPackages = @(Select-WinUtilISOWinPEDriverPackage -Packages $driverPackages -Logger $Logger)
            } catch {
                $classificationTimer.Stop()
                $null = & $Logger "Driver inventory/classification failed after $(Format-WinUtilISOElapsed -Stopwatch $classificationTimer)."
                throw
            }
            $classificationTimer.Stop()
            $null = & $Logger "Driver inventory/classification completed in $(Format-WinUtilISOElapsed -Stopwatch $classificationTimer)."

            $winpeDriverDir = Join-Path $ContentRoot '$WinPEDriver$'
            $copyFailures = 0
            foreach ($driverPackage in $winpeDriverPackages) {
                try {
                    $winpeTarget = Copy-WinUtilISODriverPackage -Source $driverPackage.Directory -Destination $winpeDriverDir
                    $null = & $Logger "Staged active storage package '$($driverPackage.Directory)' for WinPE as '$winpeTarget'."
                } catch {
                    $copyFailures++
                    $null = & $Logger "Warning: failed to stage active storage package '$($driverPackage.Directory)': $_"
                }
            }

            if ($copyFailures -gt 0) {
                throw "Failed to stage $copyFailures active storage driver package directories."
            }

            $null = & $Logger "Exported $($driverInfs.Count) driver INF files across $($driverPackages.Count) package directories; staged $($winpeDriverPackages.Count) active packages for WinPE."
            $metadataBefore = Get-WinUtilISOWimMetadata -ImagePath $InstallImagePath -Index $InstallImageIndex
            Assert-WinUtilISOWimMetadata -Before $metadataBefore

            Set-ItemProperty -LiteralPath $InstallImagePath -Name IsReadOnly -Value $false
            New-Item -Path $mountDir -ItemType Directory -Force | Out-Null
            & $Logger "Mounting install.wim index $InstallImageIndex once for driver injection..."
            Invoke-WinUtilISODism -Arguments @('/English', '/Mount-Image', "/ImageFile:$InstallImagePath", "/Index:$InstallImageIndex", "/MountDir:$mountDir") -Operation 'mount' | Out-Null
            $imageMounted = $true

            & $Logger "Adding all exported drivers to the selected Windows image in one DISM operation..."
            Invoke-WinUtilISODism -Arguments @('/English', "/Image:$mountDir", '/Add-Driver', "/Driver:$driverExportRoot", '/Recurse') -Operation 'add-driver' | Out-Null

            & $Logger 'Committing the driver-only install.wim change...'
            Invoke-WinUtilISODism -Arguments @('/English', '/Unmount-Image', "/MountDir:$mountDir", '/Commit') -Operation 'commit' | Out-Null
            $imageMounted = $false

            $metadataAfter = Get-WinUtilISOWimMetadata -ImagePath $InstallImagePath -Index $InstallImageIndex
            Assert-WinUtilISOWimMetadata -Before $metadataBefore -After $metadataAfter
            & $Logger 'Driver injection complete; install.wim metadata validation passed.'
        } finally {
            if ($imageMounted -or (Test-WinUtilISOMountedImage -Path $mountDir)) {
                try {
                    Invoke-WinUtilISODism -Arguments @('/English', '/Unmount-Image', "/MountDir:$mountDir", '/Discard') -Operation 'discard' | Out-Null
                } catch {
                    & $Logger "Warning: could not discard the failed install.wim mount: $_"
                }
            }
            Remove-Item -Path $mountDir -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $driverExportRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    function Write-WinUtilISOEditionConfig {
        param (
            [Parameter(Mandatory)][string]$ContentRoot,
            [string]$EditionId,
            [scriptblock]$Logger
        )

        $sourcesDir = Join-Path $ContentRoot "sources"
        New-Item -Path $sourcesDir -ItemType Directory -Force | Out-Null

        $pidPath = Join-Path $sourcesDir "PID.txt"
        if (Test-Path $pidPath) {
            Remove-Item -Path $pidPath -Force
            & $Logger "Removed sources\PID.txt so setup will not force a stale or mismatched product key."
        }

        if ([string]::IsNullOrWhiteSpace($EditionId)) {
            & $Logger "Warning: selected edition ID is unknown - skipping sources\ei.cfg fallback."
            return
        }

        $eiCfgPath = Join-Path $sourcesDir "ei.cfg"
        $eiCfg = @"
[EditionID]
$EditionId
[Channel]
Retail
[VL]
0
"@.Trim()

        Set-Content -Path $eiCfgPath -Value $eiCfg -Encoding ASCII -Force
        & $Logger "Written sources\ei.cfg for EditionID '$EditionId'."
    }

    function Add-WinUtilISOSetupCustomizations {
        param (
            [Parameter(Mandatory)][string]$XmlContent,
            [Parameter(Mandatory)][int]$InstallImageIndex,
            [scriptblock]$Logger
        )

        $appxPackages = @(
            'Clipchamp.Clipchamp', 'Microsoft.BingNews', 'Microsoft.BingSearch',
            'Microsoft.BingWeather', 'Microsoft.GetHelp', 'Microsoft.MicrosoftOfficeHub',
            'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftStickyNotes',
            'Microsoft.OutlookForWindows', 'Microsoft.Paint', 'Microsoft.PowerAutomateDesktop',
            'Microsoft.StartExperiencesApp', 'Microsoft.Todos', 'Microsoft.Windows.DevHome',
            'Microsoft.WindowsFeedbackHub', 'Microsoft.WindowsSoundRecorder',
            'Microsoft.ZuneMusic', 'MicrosoftCorporationII.QuickAssist', 'MSTeams'
        )

        $appxList = ($appxPackages | ForEach-Object { "    '$_'" }) -join "`r`n"
        $postInstallScript = @"
`$ErrorActionPreference = 'Continue'
`$logPath = 'C:\Windows\Setup\Scripts\WinUtil-PostInstall.log'
Start-Transcript -Path `$logPath -Append -ErrorAction SilentlyContinue

try {
    Write-Host 'WinUtil: Removing provisioned AppX packages...'
    `$packages = @(
$appxList
    )
    foreach (`$package in `$packages) {
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
            Where-Object { `$_.DisplayName -like "*`$package*" } |
            ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName `$_.PackageName -ErrorAction SilentlyContinue | Out-Null }
        Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
            Where-Object { `$_.Name -like "*`$package*" } |
            ForEach-Object { Remove-AppxPackage -AllUsers -Package `$_.PackageFullName -ErrorAction SilentlyContinue | Out-Null }
    }

    function Set-WinUtilRegistryValue([string]`$Path, [string]`$Name, [string]`$Type, [string]`$Value) {
        reg.exe add `$Path /v `$Name /t `$Type /d `$Value /f 2>&1 | Out-Null
    }

    function Set-WinUtilContentDeliveryManagerValues([string]`$HiveRoot) {
        `$contentDeliveryManager = "`$HiveRoot\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Set-WinUtilRegistryValue `$contentDeliveryManager 'OemPreInstalledAppsEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'PreInstalledAppsEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SilentInstalledAppsEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'ContentDeliveryAllowed' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'FeatureManagementEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'PreInstalledAppsEverEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SoftLandingEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SubscribedContentEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SubscribedContent-310093Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SubscribedContent-338388Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SubscribedContent-338389Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SubscribedContent-338393Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SubscribedContent-353694Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SubscribedContent-353696Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SystemPaneSuggestionsEnabled' 'REG_DWORD' '0'
        reg.exe delete "`$contentDeliveryManager\Subscriptions" /f 2>&1 | Out-Null
        reg.exe delete "`$contentDeliveryManager\SuggestedApps" /f 2>&1 | Out-Null
    }

    Write-Host 'WinUtil: Applying registry tweaks...'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager' 'ShippedWithReserves' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\CurrentControlSet\Control\BitLocker' 'PreventDeviceEncryption' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat' 'ChatIcon' 'REG_DWORD' '3'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive' 'DisableFileSyncNGSC' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\CurrentControlSet\Services\dmwappushservice' 'Start' 'REG_DWORD' '4'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'HubsSidebarEnabled' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Teams' 'DisableInstallation' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Mail' 'PreventRun' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableConsumerAccountStateContent' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableCloudOptimizedContent' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start' 'ConfigureStartPins' 'REG_SZ' '{"pinnedList": [{}]}'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' 'BypassNRO' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\Setup\LabConfig' 'BypassCPUCheck' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\Setup\LabConfig' 'BypassRAMCheck' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\Setup\LabConfig' 'BypassSecureBootCheck' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\Setup\LabConfig' 'BypassStorageCheck' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\Setup\LabConfig' 'BypassTPMCheck' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\Setup\MoSetup' 'AllowUpgradesWithUnsupportedTPMOrCPU' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\PushToInstall' 'DisablePushToInstall' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\MRT' 'DontOfferThroughWUAU' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' 'workCompleted' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate' 'workCompleted' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate' 'workCompleted' 'REG_DWORD' '1'
    reg.exe delete 'HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' /f 2>&1 | Out-Null
    reg.exe delete 'HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate' /f 2>&1 | Out-Null
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'NoAutoUpdate' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'AUOptions' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'UseWUServer' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'DisableWindowsUpdateAccess' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'WUServer' 'REG_SZ' 'http://localhost:8080'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'WUStatusServer' 'REG_SZ' 'http://localhost:8080'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\WindowsUpdate' 'workCompleted' 'REG_DWORD' '1'
    reg.exe delete 'HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\WindowsUpdate' /f 2>&1 | Out-Null
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' 'DODownloadMode' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\CurrentControlSet\Services\BITS' 'Start' 'REG_DWORD' '4'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\CurrentControlSet\Services\wuauserv' 'Start' 'REG_DWORD' '4'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc' 'Start' 'REG_DWORD' '4'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc' 'Start' 'REG_DWORD' '4'

    `$defaultHive = 'HKU\WinUtilDefault'
    reg.exe load `$defaultHive 'C:\Users\Default\NTUSER.DAT' 2>&1 | Out-Null
    if (`$LASTEXITCODE -eq 0) {
        Set-WinUtilRegistryValue "`$defaultHive\Control Panel\UnsupportedHardwareNotificationCache" 'SV1' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue "`$defaultHive\Control Panel\UnsupportedHardwareNotificationCache" 'SV2' 'REG_DWORD' '0'
        Set-WinUtilContentDeliveryManagerValues `$defaultHive
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" 'Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\Windows\CurrentVersion\Privacy" 'TailoredExperiencesWithDiagnosticDataEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" 'HasAccepted' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\Input\TIPC" 'Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\InputPersonalization" 'RestrictImplicitInkCollection' 'REG_DWORD' '1'
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\InputPersonalization" 'RestrictImplicitTextCollection' 'REG_DWORD' '1'
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\InputPersonalization\TrainedDataStore" 'HarvestContacts' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\Personalization\Settings" 'AcceptedPrivacyPolicy' 'REG_DWORD' '0'
        reg.exe unload `$defaultHive 2>&1 | Out-Null
    }

    Set-WinUtilContentDeliveryManagerValues 'HKCU'
    Set-WinUtilRegistryValue 'HKCU\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarMn' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\Input\TIPC' 'Enabled' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 'REG_DWORD' '0'

    Write-Host 'WinUtil: Removing scheduled task definitions...'
    `$taskPaths = @(
        'C:\Windows\System32\Tasks\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
        'C:\Windows\System32\Tasks\Microsoft\Windows\Customer Experience Improvement Program',
        'C:\Windows\System32\Tasks\Microsoft\Windows\Application Experience\ProgramDataUpdater',
        'C:\Windows\System32\Tasks\Microsoft\Windows\Chkdsk\Proxy',
        'C:\Windows\System32\Tasks\Microsoft\Windows\Windows Error Reporting\QueueReporting',
        'C:\Windows\System32\Tasks\Microsoft\Windows\InstallService',
        'C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator',
        'C:\Windows\System32\Tasks\Microsoft\Windows\UpdateAssistant',
        'C:\Windows\System32\Tasks\Microsoft\Windows\WaaSMedic',
        'C:\Windows\System32\Tasks\Microsoft\Windows\WindowsUpdate',
        'C:\Windows\System32\Tasks\Microsoft\WindowsUpdate'
    )
    foreach (`$taskPath in `$taskPaths) { Remove-Item -LiteralPath `$taskPath -Recurse -Force -ErrorAction SilentlyContinue }

    Start-Process -FilePath 'C:\Windows\System32\OneDriveSetup.exe' -ArgumentList '/uninstall' -Wait -ErrorAction SilentlyContinue
    Write-Host 'WinUtil: Post-install customization complete.'
} finally {
    Stop-Transcript -ErrorAction SilentlyContinue
}
"@

        $xmlDoc = [xml]::new()
        $xmlDoc.PreserveWhitespace = $true
        $xmlDoc.LoadXml($XmlContent)
        $nsMgr = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
        $nsMgr.AddNamespace('u', 'urn:schemas-microsoft-com:unattend')
        $nsMgr.AddNamespace('sg', 'https://schneegans.de/windows/unattend-generator/')

        $setupComponent = $xmlDoc.SelectSingleNode('/u:unattend/u:settings[@pass="windowsPE"]/u:component[@name="Microsoft-Windows-Setup"]', $nsMgr)
        $extensions = $xmlDoc.SelectSingleNode('//sg:Extensions', $nsMgr)
        $firstLogonFile = $xmlDoc.SelectSingleNode('//sg:File[@path="C:\Windows\Setup\Scripts\FirstLogon.ps1"]', $nsMgr)
        if (-not $setupComponent -or -not $extensions -or -not $firstLogonFile) {
            throw 'autounattend.xml is missing a required Windows Setup, Extensions, or FirstLogon.ps1 node.'
        }

        $imageInstall = $setupComponent.SelectSingleNode('u:ImageInstall', $nsMgr)
        if (-not $imageInstall) {
            $imageInstall = $xmlDoc.CreateElement('ImageInstall', $setupComponent.NamespaceURI)
            [void]$setupComponent.AppendChild($imageInstall)
        }
        $osImage = $imageInstall.SelectSingleNode('u:OSImage', $nsMgr)
        if (-not $osImage) {
            $osImage = $xmlDoc.CreateElement('OSImage', $setupComponent.NamespaceURI)
            [void]$imageInstall.AppendChild($osImage)
        }
        $installFrom = $osImage.SelectSingleNode('u:InstallFrom', $nsMgr)
        if (-not $installFrom) {
            $installFrom = $xmlDoc.CreateElement('InstallFrom', $setupComponent.NamespaceURI)
            [void]$osImage.AppendChild($installFrom)
        }
        foreach ($existingMetadata in @($installFrom.SelectNodes('u:MetaData', $nsMgr))) {
            [void]$installFrom.RemoveChild($existingMetadata)
        }
        $metadata = $xmlDoc.CreateElement('MetaData', $setupComponent.NamespaceURI)
        $action = $xmlDoc.CreateAttribute('wcm', 'action', 'http://schemas.microsoft.com/WMIConfig/2002/State')
        $action.Value = 'add'
        [void]$metadata.Attributes.Append($action)
        $key = $xmlDoc.CreateElement('Key', $setupComponent.NamespaceURI)
        $key.InnerText = '/IMAGE/INDEX'
        [void]$metadata.AppendChild($key)
        $value = $xmlDoc.CreateElement('Value', $setupComponent.NamespaceURI)
        $value.InnerText = [string]$InstallImageIndex
        [void]$metadata.AppendChild($value)
        [void]$installFrom.AppendChild($metadata)

        $postInstallFile = $xmlDoc.CreateElement('File', $extensions.NamespaceURI)
        $postInstallFile.SetAttribute('path', 'C:\Windows\Setup\Scripts\WinUtil-PostInstall.ps1')
        $postInstallFile.InnerText = $postInstallScript
        [void]$extensions.AppendChild($postInstallFile)

        $firstLogonFile.InnerText = "& 'C:\Windows\Setup\Scripts\WinUtil-PostInstall.ps1';`r`n`r`n$($firstLogonFile.InnerText.Trim())"

        $null = & $Logger 'Added WinUtil post-install AppX, registry, and scheduled-task customizations to autounattend.xml.'
        return $xmlDoc.OuterXml
    }

    function Add-WinUtilISOSetupScriptFallback {
        param (
            [Parameter(Mandatory)][string]$ContentRoot,
            [Parameter(Mandatory)][string]$XmlContent,
            [scriptblock]$Logger
        )

        $xmlDoc = [xml]::new()
        $xmlDoc.PreserveWhitespace = $true
        $xmlDoc.LoadXml($XmlContent)
        $nsMgr = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
        $nsMgr.AddNamespace('u', 'urn:schemas-microsoft-com:unattend')
        $nsMgr.AddNamespace('sg', 'https://schneegans.de/windows/unattend-generator/')

        $setupScriptsRoot = Join-Path $ContentRoot 'sources\$OEM$\$$\Setup\Scripts'
        $stagedCount = 0
        foreach ($file in $xmlDoc.SelectNodes('//sg:File', $nsMgr)) {
            $path = $file.GetAttribute('path')
            if (-not $path.StartsWith('C:\Windows\Setup\Scripts\', [System.StringComparison]::OrdinalIgnoreCase)) {
                continue
            }

            $relativePath = $path.Substring('C:\Windows\Setup\Scripts\'.Length)
            $targetPath = Join-Path $setupScriptsRoot $relativePath
            New-Item -Path (Split-Path $targetPath -Parent) -ItemType Directory -Force | Out-Null

            $encoding = switch ([System.IO.Path]::GetExtension($targetPath)) {
                { $_ -in '.ps1', '.xml' } { [System.Text.Encoding]::UTF8; break }
                { $_ -in '.reg', '.vbs', '.js' } { [System.Text.UnicodeEncoding]::new($false, $true); break }
                default { [System.Text.Encoding]::Default }
            }
            $bytes = $encoding.GetPreamble() + $encoding.GetBytes($file.InnerText.Trim())
            [System.IO.File]::WriteAllBytes($targetPath, $bytes)
            $stagedCount++
        }

        $useConfigurationSet = $xmlDoc.SelectSingleNode('/u:unattend/u:settings[@pass="windowsPE"]/u:component[@name="Microsoft-Windows-Setup"]/u:UseConfigurationSet', $nsMgr)
        if ($useConfigurationSet) {
            $useConfigurationSet.InnerText = 'false'
            [System.IO.File]::WriteAllText((Join-Path $ContentRoot 'autounattend.xml'), $xmlDoc.OuterXml, [System.Text.UTF8Encoding]::new($false))
        }
        & $Logger "Staged $stagedCount WinUtil setup script fallback files at '$setupScriptsRoot'."
    }

    if (-not (Test-Path $ISOContentsDir)) {
        throw "ISO contents directory does not exist: $ISOContentsDir"
    }

    if ([string]::IsNullOrWhiteSpace($AutoUnattendXml)) {
        throw "autounattend.xml content is required to prepare setup media."
    }

    $preparedAutoUnattendXml = Add-WinUtilISOSetupCustomizations -XmlContent $AutoUnattendXml -InstallImageIndex $InstallImageIndex -Logger $Log
    $unattendPath = Join-Path $ISOContentsDir "autounattend.xml"
    [System.IO.File]::WriteAllText($unattendPath, $preparedAutoUnattendXml, [System.Text.UTF8Encoding]::new($false))
    & $Log "Written autounattend.xml with WinUtil setup customizations to ISO root ($unattendPath)."
    Add-WinUtilISOSetupScriptFallback -ContentRoot $ISOContentsDir -XmlContent $preparedAutoUnattendXml -Logger $Log

    Write-WinUtilISOEditionConfig -ContentRoot $ISOContentsDir -EditionId $InstallEditionId -Logger $Log

    if ($InjectCurrentSystemDrivers) {
        Add-WinUtilISOStagedDrivers -ContentRoot $ISOContentsDir -Logger $Log -InstallImagePath $InstallImagePath -InstallImageIndex $InstallImageIndex
    }
}
