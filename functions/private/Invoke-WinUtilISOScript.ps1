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

    .PARAMETER DriversInjected
        Optional [ref] set to $true only if driver injection actually mounted and committed
        install.wim; stays $false if injection was skipped or no package was added successfully.
    #>
    param (
        [Parameter(Mandatory)][string]$ISOContentsDir,
        [string]$AutoUnattendXml = "",
        [bool]$InjectCurrentSystemDrivers = $false,
        [string]$InstallEditionId = "",
        [string]$InstallImagePath = "",
        [int]$InstallImageIndex = 1,
        [scriptblock]$Log = { param($m) Write-Output $m },
        [ref]$DriversInjected = [ref]$false
    )

    function Add-WinUtilISOStagedDrivers {
        param (
            [Parameter(Mandatory)][string]$ContentRoot,
            [Parameter(Mandatory)][string]$InstallImagePath,
            [Parameter(Mandatory)][int]$InstallImageIndex,
            [scriptblock]$Logger,
            [ref]$DriversInjected = [ref]$false
        )
        $DriversInjected.Value = $false

        function Copy-WinUtilISODriverFolder {
            param (
                [Parameter(Mandatory)][string]$Source,
                [Parameter(Mandatory)][string]$Destination
            )

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

        function Test-WinUtilISOStorageDriver {
            param ([Parameter(Mandatory)][System.IO.FileInfo]$InfFile)

            if ($InfFile.BaseName -match '(?i)(iaahci|iastor|vmd|irst|rst)') {
                return $true
            }

            try {
                return (Get-Content -LiteralPath $InfFile.FullName -Raw -ErrorAction Stop) -match '(?im)^\s*Class\s*=\s*(SCSIAdapter|HDC)\s*(?:;.*)?$'
            } catch {
                & $Logger "Warning: could not classify storage driver '$($InfFile.FullName)': $_"
                return $false
            }
        }

        function Test-WinUtilISODriverExtensionClass {
            param ([Parameter(Mandatory)][System.IO.FileInfo]$InfFile)

            try {
                return (Get-Content -LiteralPath $InfFile.FullName -Raw -ErrorAction Stop) -match '(?im)^\s*Class\s*=\s*"?Extension"?\s*(?:;.*)?$'
            } catch {
                $null = & $Logger "Warning: could not classify driver '$($InfFile.FullName)': $_"
                return $false
            }
        }

        function Get-WinUtilISODriverPackageVersion {
            param ([Parameter(Mandatory)][System.IO.FileInfo]$InfFile)

            try {
                $infText = Get-Content -LiteralPath $InfFile.FullName -Raw -ErrorAction Stop
            } catch {
                $null = & $Logger "Warning: could not read '$($InfFile.FullName)' to determine its driver version: $_"
                return $null
            }

            # The version component of DriverVer is optional per the INF spec (date-only entries
            # are valid); treat a missing version as 0.0 so date-only entries still rank correctly
            # instead of being discarded as unparseable.
            $match = [regex]::Match($infText, '(?im)^\s*DriverVer\s*=\s*(?<date>\d{1,2}/\d{1,2}/\d{4})\s*(?:,\s*(?<version>\d+(?:\.\d+){0,3}))?\s*(?:;.*)?$')
            if (-not $match.Success) {
                return $null
            }

            try {
                $date = [datetime]::ParseExact($match.Groups['date'].Value, 'M/d/yyyy', [System.Globalization.CultureInfo]::InvariantCulture)
                $versionText = if ($match.Groups['version'].Success) { $match.Groups['version'].Value } else { '0' }
                if (($versionText.Split('.')).Count -lt 2) {
                    $versionText = "$versionText.0"
                }
                $version = [version]$versionText
            } catch {
                $null = & $Logger "Warning: could not parse DriverVer '$($match.Value.Trim())' in '$($InfFile.FullName)': $_"
                return $null
            }

            return [pscustomobject]@{
                Date    = $date
                Version = $version
                Raw     = if ($match.Groups['version'].Success) { "$($match.Groups['date'].Value),$($match.Groups['version'].Value)" } else { $match.Groups['date'].Value }
            }
        }

        function Get-WinUtilISODriverProvider {
            param ([Parameter(Mandatory)][System.IO.FileInfo]$InfFile)

            try {
                $infText = Get-Content -LiteralPath $InfFile.FullName -Raw -ErrorAction Stop
            } catch {
                $null = & $Logger "Warning: could not read '$($InfFile.FullName)' to determine its provider: $_"
                return ''
            }

            $match = [regex]::Match($infText, '(?im)^\s*Provider\s*=\s*(?<provider>.+?)\s*(?:;.*)?$')
            if (-not $match.Success) {
                return ''
            }
            return $match.Groups['provider'].Value.ToLowerInvariant()
        }

        function Select-WinUtilISOStagedDriverPackages {
            param (
                [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$DriverFolderGroups,
                [scriptblock]$Logger
            )

            $survivingFolders = [System.Collections.Generic.List[string]]::new()
            $dedupGroups = @{}

            foreach ($driverFolderGroup in $DriverFolderGroups) {
                $driverFolder = [string]$driverFolderGroup.Name
                $isExtension = [bool]@($driverFolderGroup.Group | Where-Object { Test-WinUtilISODriverExtensionClass -InfFile $_ }).Count

                if ($isExtension) {
                    # $null = discards $Logger's own output; this function's return value is captured
                    # by the caller, and an emitting logger (e.g. this function's own default) would
                    # otherwise leak into the surviving-folder list.
                    $null = & $Logger "Excluding extension-class driver package '$driverFolder' from Add-Driver (Class=Extension is not a serviceable hardware driver)."
                    continue
                }

                # DISM names exported package folders <infname>_<arch>_<hash>; grouping on infname+arch
                # (dropping the hash) is what lets us recognize two exports of the same driver. When a
                # folder doesn't match that pattern, fall back to the full path rather than the leaf name:
                # two unrelated folders at different depths (e.g. group_a\duplicate and group_b\duplicate)
                # can share a leaf name, and the full path is guaranteed unique per group.
                $leafName = Split-Path -Path $driverFolder -Leaf
                $dedupKey = $driverFolder
                $nameMatch = [regex]::Match($leafName, '(?i)^(?<infname>.+)_(?<arch>x86|amd64|arm64|arm|wow)_[0-9a-f]{16}$')
                if ($nameMatch.Success) {
                    $provider = Get-WinUtilISODriverProvider -InfFile $driverFolderGroup.Group[0]
                    $dedupKey = "$($nameMatch.Groups['infname'].Value.ToLowerInvariant())_$($nameMatch.Groups['arch'].Value.ToLowerInvariant())_$provider"
                }

                if (-not $dedupGroups.ContainsKey($dedupKey)) {
                    $dedupGroups[$dedupKey] = [System.Collections.Generic.List[object]]::new()
                }
                $dedupGroups[$dedupKey].Add($driverFolderGroup)
            }

            foreach ($dedupKey in $dedupGroups.Keys) {
                $candidates = $dedupGroups[$dedupKey]
                if ($candidates.Count -eq 1) {
                    $survivingFolders.Add([string]$candidates[0].Name)
                    continue
                }

                $ranked = @($candidates | ForEach-Object {
                    $primaryVersion = ($_.Group | ForEach-Object { Get-WinUtilISODriverPackageVersion -InfFile $_ } | Where-Object { $_ }) |
                        Sort-Object -Property Date, Version -Descending | Select-Object -First 1
                    [pscustomobject]@{ Folder = [string]$_.Name; Version = $primaryVersion }
                })

                $withVersion = @($ranked | Where-Object { $_.Version })
                if ($withVersion.Count -eq 0) {
                    $null = & $Logger "Warning: could not determine DriverVer for any duplicate of '$dedupKey'; keeping all $($ranked.Count) package(s) rather than guessing."
                    foreach ($candidate in $ranked) {
                        $survivingFolders.Add($candidate.Folder)
                    }
                    continue
                }

                $kept = $withVersion | Sort-Object -Property @{ Expression = { $_.Version.Date } }, @{ Expression = { $_.Version.Version } } -Descending | Select-Object -First 1
                $survivingFolders.Add($kept.Folder)

                foreach ($candidate in $ranked) {
                    if ($candidate.Folder -eq $kept.Folder) {
                        continue
                    }
                    $droppedVersion = if ($candidate.Version) { $candidate.Version.Raw } else { 'unknown' }
                    $null = & $Logger "Excluding stale duplicate driver package '$($candidate.Folder)' (DriverVer $droppedVersion) superseded by '$($kept.Folder)' (DriverVer $($kept.Version.Raw))."
                }
            }

            return @($survivingFolders)
        }

        function Invoke-WinUtilISODism {
            param (
                [Parameter(Mandatory)][string[]]$Arguments,
                [Parameter(Mandatory)][string]$Operation
            )

            $output = @(& dism.exe @Arguments 2>&1)
            $exitCode = $LASTEXITCODE
            if ($exitCode -ne 0) {
                foreach ($line in @($output | Select-Object -Last 20)) {
                    if (-not [string]::IsNullOrWhiteSpace([string]$line)) {
                        & $Logger "  dism[$Operation]: $line"
                    }
                }
                throw "DISM $Operation failed with exit code $exitCode."
            }
            if ($Operation -ne 'metadata') {
                & $Logger "DISM $Operation completed."
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

        # %TEMP% can be an 8.3 alias, but Get-ChildItem below reports long paths, so the
        # exported folders would not share this prefix unless it is expanded first.
        $driverExportRoot = (Get-Item -LiteralPath $driverExportRoot).FullName
        $imageMounted = $false

        try {
            & $Logger "Exporting current system drivers before modifying install.wim..."
            $dismLog = Join-Path $env:TEMP "WinUtil_DismDriverExport_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
            Invoke-WinUtilISODism -Arguments @('/English', '/Online', '/Export-Driver', "/Destination:$driverExportRoot", "/LogPath:$dismLog") -Operation 'export-driver' | Out-Null

            $driverInfs = @(Get-ChildItem -LiteralPath $driverExportRoot -Filter '*.inf' -Recurse -File)
            if ($driverInfs.Count -eq 0) {
                throw 'DISM exported no driver INF files.'
            }
            $driverFolders = @($driverInfs | Group-Object { $_.Directory.FullName })
            $winpeDriverDir = Join-Path $ContentRoot '$WinpeDriver$'
            $storageCount = 0
            $copyFailures = 0

            foreach ($driverFolderGroup in $driverFolders) {
                $driverFolder = [string]$driverFolderGroup.Name
                $storageInfs = @($driverFolderGroup.Group | Where-Object { Test-WinUtilISOStorageDriver -InfFile $_ })
                if ($storageInfs.Count -eq 0) {
                    continue
                }

                try {
                    New-Item -Path $winpeDriverDir -ItemType Directory -Force | Out-Null
                    $winpeTarget = Copy-WinUtilISODriverFolder -Source $driverFolder -Destination $winpeDriverDir
                    $storageCount++
                    & $Logger "Staged boot-storage package '$driverFolder' for WinPE as '$winpeTarget'."
                } catch {
                    $copyFailures++
                    & $Logger "Warning: failed to stage boot-storage package '$driverFolder': $_"
                }
            }

            if ($copyFailures -gt 0) {
                throw "Failed to stage $copyFailures boot-storage driver package folders."
            }

            $stagedDriverFolders = @(Select-WinUtilISOStagedDriverPackages -DriverFolderGroups $driverFolders -Logger $Logger)
            $metadataBefore = Get-WinUtilISOWimMetadata -ImagePath $InstallImagePath -Index $InstallImageIndex
            Assert-WinUtilISOWimMetadata -Before $metadataBefore

            if ($stagedDriverFolders.Count -eq 0) {
                # Nothing safe to inject (e.g. every exported package was an Extension-class add-on)
                # isn't a failure: leave install.wim untouched and continue building the ISO.
                & $Logger 'No drivers found to inject: every exported package was excluded (Extension class or stale duplicate). Skipping driver injection; install.wim is unchanged.'
            } else {
                $excludedDriverFolderGroups = @($driverFolders | Where-Object { $_.Name -notin $stagedDriverFolders })
                foreach ($excludedDriverFolderGroup in $excludedDriverFolderGroups) {
                    $excludedFolder = [string]$excludedDriverFolderGroup.Name
                    $hasRetainedDescendant = [bool]@($stagedDriverFolders | Where-Object {
                        $_.StartsWith("$excludedFolder\", [System.StringComparison]::OrdinalIgnoreCase)
                    }).Count
                    if ($hasRetainedDescendant) {
                        try {
                            foreach ($excludedInf in $excludedDriverFolderGroup.Group) {
                                Remove-Item -LiteralPath $excludedInf.FullName -Force -ErrorAction Stop
                            }
                        } catch {
                            throw "Failed to remove excluded driver INF files from package '$excludedFolder' before injection: $_"
                        }

                        & $Logger "Keeping excluded driver package directory '$excludedFolder' because it contains a retained nested package, after removing its excluded INF files."
                        continue
                    }

                    try {
                        Remove-Item -LiteralPath $excludedFolder -Recurse -Force -ErrorAction Stop
                    } catch {
                        throw "Failed to remove excluded driver package '$excludedFolder' before injection: $_"
                    }
                }

                & $Logger "Exported $($stagedDriverFolders.Count) of $($driverFolders.Count) driver packages ($storageCount staged for WinPE, $($excludedDriverFolderGroups.Count) excluded)."

                Set-ItemProperty -LiteralPath $InstallImagePath -Name IsReadOnly -Value $false
                New-Item -Path $mountDir -ItemType Directory -Force | Out-Null

                # Add each package separately so one bad driver cannot fail the rest. Because
                # /Recurse covers descendants, only the highest surviving folder in each tree
                # needs its own DISM call.
                $rootPackageFolders = @($stagedDriverFolders | Where-Object {
                    $candidate = $_
                    -not ($stagedDriverFolders | Where-Object { $candidate.StartsWith("$_\", [System.StringComparison]::OrdinalIgnoreCase) })
                })

                & $Logger "Adding $($rootPackageFolders.Count) root driver packages to install.wim."
                $remainingDriverFolders = @($rootPackageFolders)
                while ($remainingDriverFolders.Count -gt 0) {
                    & $Logger "Mounting install.wim index $InstallImageIndex for driver injection..."
                    Invoke-WinUtilISODism -Arguments @('/English', '/Mount-Image', "/ImageFile:$InstallImagePath", "/Index:$InstallImageIndex", "/MountDir:$mountDir") -Operation 'mount' | Out-Null
                    $imageMounted = $true

                    $failedDriverFolder = $null
                    foreach ($driverFolder in $remainingDriverFolders) {
                        $driverName = $driverFolder
                        if ($driverFolder.StartsWith($driverExportRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                            $driverName = $driverFolder.Substring($driverExportRoot.Length).TrimStart('\')
                        }

                        try {
                            Invoke-WinUtilISODism -Arguments @('/English', "/Image:$mountDir", '/Add-Driver', "/Driver:$driverFolder", '/Recurse') -Operation "add-driver:$driverName" | Out-Null
                        } catch {
                            & $Logger "Warning: failed to add driver package '$driverName': $_"
                            $failedDriverFolder = $driverFolder
                            break
                        }
                    }

                    if (-not $failedDriverFolder) {
                        break
                    }

                    & $Logger "Discarding the potentially partial install.wim mount before continuing without '$driverName'."
                    try {
                        Invoke-WinUtilISODism -Arguments @('/English', '/Unmount-Image', "/MountDir:$mountDir", '/Discard') -Operation 'discard' | Out-Null
                        $imageMounted = $false
                    } catch {
                        throw "Failed to discard the potentially partial install.wim mount after driver package '$driverName' failed: $_"
                    }

                    $remainingDriverFolders = @($remainingDriverFolders | Where-Object { $_ -ne $failedDriverFolder })
                }

                $addedCount = $remainingDriverFolders.Count
                if ($addedCount -eq 0) {
                    # Boot-storage drivers staged for WinPE remain available to Windows Setup.
                    & $Logger "Warning: none of the $($rootPackageFolders.Count) exported driver packages could be added; continuing with an unmodified install.wim."
                } else {
                    & $Logger "Added $addedCount of $($rootPackageFolders.Count) driver packages to install.wim."
                    & $Logger 'Committing the driver-only install.wim change...'
                    Invoke-WinUtilISODism -Arguments @('/English', '/Unmount-Image', "/MountDir:$mountDir", '/Commit') -Operation 'commit' | Out-Null
                    $imageMounted = $false

                    $metadataAfter = Get-WinUtilISOWimMetadata -ImagePath $InstallImagePath -Index $InstallImageIndex
                    Assert-WinUtilISOWimMetadata -Before $metadataBefore -After $metadataAfter
                    & $Logger 'Driver injection complete; install.wim metadata validation passed.'
                    $DriversInjected.Value = $true
                }
            }
        } finally {
            if ($imageMounted -or (Test-WinUtilISOMountedImage -Path $mountDir)) {
                try {
                    Invoke-WinUtilISODism -Arguments @('/English', '/Unmount-Image', "/MountDir:$mountDir", '/Discard') -Operation 'discard' | Out-Null
                } catch {
                    & $Logger "Warning: could not discard the failed install.wim mount: $_"
                }
            }
            Remove-Item -LiteralPath $mountDir -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $driverExportRoot -Recurse -Force -ErrorAction SilentlyContinue
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
            $useConfigurationSet.InnerText = 'true'
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
        Add-WinUtilISOStagedDrivers -ContentRoot $ISOContentsDir -Logger $Log -InstallImagePath $InstallImagePath -InstallImageIndex $InstallImageIndex -DriversInjected $DriversInjected
    }
}
