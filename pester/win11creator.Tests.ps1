#===========================================================================
# Tests - Win11 Creator
#===========================================================================

Describe "Win11 Creator setup media" {
    BeforeAll {
        $script:repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
        $script:isoWorkflowPath = Join-Path $script:repoRoot "functions\private\Invoke-WinUtilISO.ps1"
        $script:isoUsbWorkflowPath = Join-Path $script:repoRoot "functions\private\Invoke-WinUtilISOUSB.ps1"
        $script:isoScriptPath = Join-Path $script:repoRoot "functions\private\Invoke-WinUtilISOScript.ps1"
        $script:autoUnattendPath = Join-Path $script:repoRoot "tools\autounattend.xml"

        function Get-WinUtilFunctionText {
            param (
                [Parameter(Mandatory)][string]$Path,
                [Parameter(Mandatory)][string]$FunctionName
            )

            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path), [ref]$tokens, [ref]$errors)
            if ($errors.Count -gt 0) {
                throw "Unable to parse $Path`: $($errors[0].Message)"
            }

            $functionAst = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq $FunctionName
            }, $true)

            if (-not $functionAst) {
                throw "Unable to find function $FunctionName in $Path."
            }

            return $functionAst.Extent.Text
        }

        $script:modifyFunction = Get-WinUtilFunctionText -Path $script:isoWorkflowPath -FunctionName "Invoke-WinUtilISOModify"
        $script:mountAndVerifyFunction = Get-WinUtilFunctionText -Path $script:isoWorkflowPath -FunctionName "Invoke-WinUtilISOMountAndVerify"
        $script:cleanAndResetFunction = Get-WinUtilFunctionText -Path $script:isoWorkflowPath -FunctionName "Invoke-WinUtilISOCleanAndReset"
        $script:exportFunction = Get-WinUtilFunctionText -Path $script:isoWorkflowPath -FunctionName "Invoke-WinUtilISOExport"
        $script:writeUsbFunction = Get-WinUtilFunctionText -Path $script:isoUsbWorkflowPath -FunctionName "Invoke-WinUtilISOWriteUSB"
        $script:editionIdFunction = Get-WinUtilFunctionText -Path $script:isoWorkflowPath -FunctionName "Get-WinUtilEditionIdFromName"
        $script:wimMetadataAssertionFunction = Get-WinUtilFunctionText -Path $script:isoScriptPath -FunctionName "Assert-WinUtilISOWimMetadata"
        $script:driverClassifierFunctions = @(
            'Get-WinUtilISODriverPackageInventory',
            'Get-WinUtilISOActiveStorageDriverMapping',
            'Select-WinUtilISOWinPEDriverPackage',
            'Copy-WinUtilISODriverPackage'
        ) | ForEach-Object { Get-WinUtilFunctionText -Path $script:isoScriptPath -FunctionName $_ }
    }

    It "autounattend template does not force a product key" {
        [xml]$xml = Get-Content -Path $script:autoUnattendPath -Raw
        $nsMgr = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
        $nsMgr.AddNamespace("u", "urn:schemas-microsoft-com:unattend")

        $productKeyCount = $xml.SelectNodes("//u:ProductKey", $nsMgr).Count
        if ($productKeyCount -ne 0) {
            throw "Expected no ProductKey nodes, found $productKeyCount."
        }
    }

    It "sets every hardware bypass before Windows Setup checks requirements" {
        [xml]$xml = Get-Content -Path $script:autoUnattendPath -Raw
        $nsMgr = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
        $nsMgr.AddNamespace("u", "urn:schemas-microsoft-com:unattend")
        $paths = @($xml.SelectNodes('/u:unattend/u:settings[@pass="windowsPE"]/u:component[@name="Microsoft-Windows-Setup"]/u:RunSynchronous/u:RunSynchronousCommand/u:Path', $nsMgr) | ForEach-Object InnerText) -join "`n"

        foreach ($bypass in 'BypassTPMCheck', 'BypassSecureBootCheck', 'BypassRAMCheck', 'BypassCPUCheck', 'BypassStorageCheck') {
            $paths | Should -Match ([regex]::Escape($bypass))
        }
    }

    It "sets OOBE-sensitive registry values before OOBE starts" {
        [xml]$xml = Get-Content -Path $script:autoUnattendPath -Raw
        $nsMgr = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
        $nsMgr.AddNamespace("u", "urn:schemas-microsoft-com:unattend")
        $paths = @($xml.SelectNodes('/u:unattend/u:settings[@pass="specialize"]/u:component[@name="Microsoft-Windows-Deployment"]/u:RunSynchronous/u:RunSynchronousCommand/u:Path', $nsMgr) | ForEach-Object InnerText) -join "`n"

        foreach ($valueName in 'BypassNRO', 'PreventDeviceEncryption', 'ShippedWithReserves') {
            $paths | Should -Match ([regex]::Escape($valueName))
        }
    }

    It "ISO script accepts selected edition and driver-only WIM servicing metadata" {
        $isoScriptPath = Join-Path $PSScriptRoot "..\functions\private\Invoke-WinUtilISOScript.ps1"
        $content = Get-Content -Path $isoScriptPath -Raw

        foreach ($pattern in @(
            '\[string\]\$InstallEditionId',
            '\[string\]\$InstallImagePath',
            '\[int\]\$InstallImageIndex',
            'sources\\ei\.cfg',
            'PID\.txt'
        )) {
            if ($content -notmatch $pattern) {
                throw "Expected Invoke-WinUtilISOScript.ps1 to match pattern: $pattern"
            }
        }
    }

    It "starts each new ISO modification in a fresh working directory" {
        foreach ($expectedText in @(
            '$workDir = Join-Path $env:TEMP "WinUtil_Win11ISO_$(Get-Date -Format ''yyyyMMdd_HHmmss'')"',
            '$workDir = Join-Path $env:TEMP "WinUtil_Win11ISO_$(Get-Date -Format ''yyyyMMdd_HHmmss'')_$(([guid]::NewGuid()).ToString(''N'').Substring(0, 8))"'
        )) {
            $script:modifyFunction | Should -Match ([regex]::Escape($expectedText))
        }

        $script:modifyFunction | Should -Not -Match ([regex]::Escape("Reusing existing temp directory"))
    }

    It "keeps WIM servicing limited to one driver-only mount and commit" {
        $isoScriptContent = Get-Content -Path $script:isoScriptPath -Raw

        foreach ($expectedText in @(
            "'/Mount-Image'",
            "'/Add-Driver'",
            "'/Commit'",
            "`$mountDir = Join-Path (Split-Path -Path `$ContentRoot -Parent) 'wim_mount'",
            'install.wim metadata validation passed'
        )) {
            $isoScriptContent | Should -Match ([regex]::Escape($expectedText))
        }

        foreach ($forbiddenText in @(
            'Mount-WindowsImage',
            'Dismount-WindowsImage',
            'Export-WindowsImage',
            'Set-WindowsImage',
            '/ResetBase',
            '/Cleanup-Image'
        )) {
            $isoScriptContent | Should -Not -Match ([regex]::Escape($forbiddenText))
        }
    }

    It "uses active storage-path inventory without adding another driver delivery path" {
        $isoScriptContent = Get-Content -Path $script:isoScriptPath -Raw

        $isoScriptContent | Should -Match ([regex]::Escape("Join-Path `$ContentRoot '`$WinPEDriver$'"))
        $isoScriptContent | Should -Match ([regex]::Escape("Get-PnpDeviceProperty -InstanceId `$deviceId -KeyName 'DEVPKEY_Device_Parent'"))
        $isoScriptContent | Should -Match ([regex]::Escape('& pnputil.exe /enum-drivers /format csv'))
        $isoScriptContent | Should -Not -Match 'Class\s*=\s*\(SCSIAdapter\|HDC\)'
        $isoScriptContent | Should -Not -Match ([regex]::Escape('sources\$OEM$\$$\Drivers'))
        $isoScriptContent | Should -Not -Match ([regex]::Escape('WinUtil-InstallDrivers.ps1'))
        $isoScriptContent | Should -Not -Match ([regex]::Escape('SetupComplete.cmd'))
    }

    It "rejects invalid WIM metadata before and after driver injection" {
        . ([scriptblock]::Create($script:wimMetadataAssertionFunction))

        $valid = @{ Languages = 'en-US'; Installation = 'Client'; Edition = 'Professional'; ProductSuite = 'Terminal Server'; ProductType = 'WinNT' }
        $invalidBefore = $valid.Clone()
        $invalidBefore.Edition = '<undefined>'
        $invalidAfter = $valid.Clone()
        $invalidAfter.ProductType = '<undefined>'

        { Assert-WinUtilISOWimMetadata -Before $invalidBefore } | Should -Throw '*already invalid*'
        { Assert-WinUtilISOWimMetadata -Before $valid -After $invalidAfter } | Should -Throw '*validation failed*'
    }

    It "maps the active system-disk parent chain from published to original INF names" {
        . ([scriptblock]::Create($script:driverClassifierFunctions[1]))

        $logicalDisk = New-CimInstance -ClassName Win32_LogicalDisk -ClientOnly -Property @{ DeviceID = $env:SystemDrive }
        $partition = New-CimInstance -ClassName Win32_DiskPartition -ClientOnly -Property @{ DeviceID = 'Disk #0, Partition #1' }
        Mock Get-CimInstance {
            param($ClassName)
            if ($ClassName -eq 'Win32_PnPSignedDriver') {
                return @(
                    [pscustomobject]@{ DeviceID = 'SCSI\DISK0'; InfName = 'disk.inf'; DeviceClass = 'DiskDrive' },
                    [pscustomobject]@{ DeviceID = 'PCI\STORAGE0'; InfName = 'oem10.inf'; DeviceClass = 'SCSIAdapter' }
                )
            }
            if ($ClassName -eq 'Win32_LogicalDisk') {
                return $logicalDisk
            }
        }
        Mock Get-CimAssociatedInstance {
            param($Association)
            if ($Association -eq 'Win32_LogicalDiskToPartition') {
                return $partition
            }
            return [pscustomobject]@{ PNPDeviceID = 'SCSI\DISK0' }
        }
        Mock Get-PnpDeviceProperty {
            param($InstanceId)
            [pscustomobject]@{ Data = if ($InstanceId -eq 'SCSI\DISK0') { 'PCI\STORAGE0' } else { $null } }
        }
        function pnputil.exe {
            $global:LASTEXITCODE = 0
            'DriverName,OriginalName,ProviderName'
            '"oem10.inf","iaStorVD.inf","Intel"'
        }

        try {
            $logs = [System.Collections.Generic.List[string]]::new()
            $mappings = @(Get-WinUtilISOActiveStorageDriverMapping -Logger { param($message) $null = $logs.Add([string]$message) })

            $mappings.Count | Should -Be 1
            $mappings[0].PublishedInfName | Should -Be 'oem10.inf'
            $mappings[0].OriginalInfName | Should -Be 'iaStorVD.inf'
            ($logs -join '|') | Should -Match 'Ignoring inbox INF names.*disk\.inf'
            ($logs -join '|') | Should -Match "Mapped active driver 'oem10.inf' to original INF 'iaStorVD.inf'"
            Should -Invoke Get-PnpDeviceProperty -Times 2 -Exactly
        } finally {
            Remove-Item Function:\pnputil.exe -ErrorAction SilentlyContinue
        }
    }

    It "excludes OEM INFs on ancestors beyond the storage-enumeration device classes" {
        . ([scriptblock]::Create($script:driverClassifierFunctions[1]))

        $logicalDisk = New-CimInstance -ClassName Win32_LogicalDisk -ClientOnly -Property @{ DeviceID = $env:SystemDrive }
        $partition = New-CimInstance -ClassName Win32_DiskPartition -ClientOnly -Property @{ DeviceID = 'Disk #0, Partition #1' }
        Mock Get-CimInstance {
            param($ClassName)
            if ($ClassName -eq 'Win32_PnPSignedDriver') {
                return @(
                    [pscustomobject]@{ DeviceID = 'SCSI\DISK0'; InfName = 'disk.inf'; DeviceClass = 'DiskDrive' },
                    [pscustomobject]@{ DeviceID = 'PCI\STORAGE0'; InfName = 'stornvme.inf'; DeviceClass = 'SCSIAdapter' },
                    [pscustomobject]@{ DeviceID = 'PCI\ROOTPORT0'; InfName = 'oem2.inf'; DeviceClass = 'System' }
                )
            }
            if ($ClassName -eq 'Win32_LogicalDisk') {
                return $logicalDisk
            }
        }
        Mock Get-CimAssociatedInstance {
            param($Association)
            if ($Association -eq 'Win32_LogicalDiskToPartition') {
                return $partition
            }
            return [pscustomobject]@{ PNPDeviceID = 'SCSI\DISK0' }
        }
        Mock Get-PnpDeviceProperty {
            param($InstanceId)
            $parentByDeviceId = @{ 'SCSI\DISK0' = 'PCI\STORAGE0'; 'PCI\STORAGE0' = 'PCI\ROOTPORT0' }
            [pscustomobject]@{ Data = $parentByDeviceId[$InstanceId] }
        }
        function pnputil.exe { throw 'PnPUtil should not run for a device outside the storage-enumeration classes.' }

        try {
            $logs = [System.Collections.Generic.List[string]]::new()
            @(Get-WinUtilISOActiveStorageDriverMapping -Logger { param($message) $null = $logs.Add([string]$message) }).Count | Should -Be 0
            Should -Invoke Get-PnpDeviceProperty -Times 2 -Exactly
            ($logs -join '|') | Should -Not -Match 'oem2\.inf'
            ($logs -join '|') | Should -Match "Stopped at PnP ancestor 'PCI\\ROOTPORT0' outside the storage-enumeration device classes"
        } finally {
            Remove-Item Function:\pnputil.exe -ErrorAction SilentlyContinue
        }
    }

    It "includes an OEM controller two hops above the disk when every ancestor is a storage-enumeration class" {
        . ([scriptblock]::Create($script:driverClassifierFunctions[1]))

        $logicalDisk = New-CimInstance -ClassName Win32_LogicalDisk -ClientOnly -Property @{ DeviceID = $env:SystemDrive }
        $partition = New-CimInstance -ClassName Win32_DiskPartition -ClientOnly -Property @{ DeviceID = 'Disk #0, Partition #1' }
        Mock Get-CimInstance {
            param($ClassName)
            if ($ClassName -eq 'Win32_PnPSignedDriver') {
                return @(
                    [pscustomobject]@{ DeviceID = 'SCSI\DISK0'; InfName = 'disk.inf'; DeviceClass = 'DiskDrive' },
                    [pscustomobject]@{ DeviceID = 'PCI\NVME0'; InfName = 'stornvme.inf'; DeviceClass = 'SCSIAdapter' },
                    [pscustomobject]@{ DeviceID = 'PCI\VMD0'; InfName = 'oem5.inf'; DeviceClass = 'SCSIAdapter' }
                )
            }
            if ($ClassName -eq 'Win32_LogicalDisk') {
                return $logicalDisk
            }
        }
        Mock Get-CimAssociatedInstance {
            param($Association)
            if ($Association -eq 'Win32_LogicalDiskToPartition') {
                return $partition
            }
            return [pscustomobject]@{ PNPDeviceID = 'SCSI\DISK0' }
        }
        Mock Get-PnpDeviceProperty {
            param($InstanceId)
            $parentByDeviceId = @{ 'SCSI\DISK0' = 'PCI\NVME0'; 'PCI\NVME0' = 'PCI\VMD0' }
            [pscustomobject]@{ Data = $parentByDeviceId[$InstanceId] }
        }
        function pnputil.exe {
            $global:LASTEXITCODE = 0
            'DriverName,OriginalName,ProviderName'
            '"oem5.inf","iaStorAVC.inf","Intel"'
        }

        try {
            $logs = [System.Collections.Generic.List[string]]::new()
            $mappings = @(Get-WinUtilISOActiveStorageDriverMapping -Logger { param($message) $null = $logs.Add([string]$message) })

            $mappings.Count | Should -Be 1
            $mappings[0].PublishedInfName | Should -Be 'oem5.inf'
            $mappings[0].OriginalInfName | Should -Be 'iaStorAVC.inf'
            Should -Invoke Get-PnpDeviceProperty -Times 3 -Exactly
        } finally {
            Remove-Item Function:\pnputil.exe -ErrorAction SilentlyContinue
        }
    }

    It "allows a verified inbox-only active path to produce an empty WinPE mapping" {
        . ([scriptblock]::Create($script:driverClassifierFunctions[1]))

        $logicalDisk = New-CimInstance -ClassName Win32_LogicalDisk -ClientOnly -Property @{ DeviceID = $env:SystemDrive }
        $partition = New-CimInstance -ClassName Win32_DiskPartition -ClientOnly -Property @{ DeviceID = 'Disk #0, Partition #1' }
        Mock Get-CimInstance {
            param($ClassName)
            if ($ClassName -eq 'Win32_PnPSignedDriver') {
                return [pscustomobject]@{ DeviceID = 'SCSI\DISK0'; InfName = 'disk.inf' }
            }
            if ($ClassName -eq 'Win32_LogicalDisk') {
                return $logicalDisk
            }
        }
        Mock Get-CimAssociatedInstance {
            param($Association)
            if ($Association -eq 'Win32_LogicalDiskToPartition') {
                return $partition
            }
            return [pscustomobject]@{ PNPDeviceID = 'SCSI\DISK0' }
        }
        Mock Get-PnpDeviceProperty { [pscustomobject]@{ Data = $null } }
        function pnputil.exe { throw 'PnPUtil should not run without an active OEM INF.' }

        try {
            $logs = [System.Collections.Generic.List[string]]::new()
            @(Get-WinUtilISOActiveStorageDriverMapping -Logger { param($message) $null = $logs.Add([string]$message) }).Count | Should -Be 0
            ($logs -join '|') | Should -Match 'no third-party OEM INF requiring WinPE staging'
        } finally {
            Remove-Item Function:\pnputil.exe -ErrorAction SilentlyContinue
        }
    }

    It "fails explicitly for unusable PnPUtil driver inventory" -TestCases @(
        @{ InventoryOutput = @(); ExitCode = 5; ExpectedError = '*PnPUtil driver inventory exited with code 5*' }
        @{ InventoryOutput = @(); ExitCode = 0; ExpectedError = '*empty CSV output*' }
        @{ InventoryOutput = @('DriverName,OriginalName'); ExitCode = 0; ExpectedError = '*contained no driver records*' }
        @{ InventoryOutput = @('DriverName,DriverName,OriginalName', '"oem10.inf","duplicate","storage.inf"'); ExitCode = 0; ExpectedError = '*CSV could not be parsed*' }
        @{ InventoryOutput = @('DriverName,ProviderName', '"oem10.inf","Vendor"'); ExitCode = 0; ExpectedError = '*missing DriverName or OriginalName*' }
        @{ InventoryOutput = @('DriverName,OriginalName', '"oem10.inf",""'); ExitCode = 0; ExpectedError = '*unusable DriverName or OriginalName*' }
        @{ InventoryOutput = @('DriverName,OriginalName', '"oem10.inf","storage.inf"', '"oem10.inf","storage-old.inf"'); ExitCode = 0; ExpectedError = '*multiple records for published INF ''oem10.inf''*' }
        @{ InventoryOutput = @('DriverName,OriginalName', '"oem11.inf","other.inf"'); ExitCode = 0; ExpectedError = '*did not translate published INF ''oem10.inf''*' }
    ) {
        param($InventoryOutput, $ExitCode, $ExpectedError)

        . ([scriptblock]::Create($script:driverClassifierFunctions[1]))
        $logicalDisk = New-CimInstance -ClassName Win32_LogicalDisk -ClientOnly -Property @{ DeviceID = $env:SystemDrive }
        $partition = New-CimInstance -ClassName Win32_DiskPartition -ClientOnly -Property @{ DeviceID = 'Disk #0, Partition #1' }
        Mock Get-CimInstance {
            param($ClassName)
            if ($ClassName -eq 'Win32_PnPSignedDriver') {
                return [pscustomobject]@{ DeviceID = 'SCSI\DISK0'; InfName = 'oem10.inf' }
            }
            if ($ClassName -eq 'Win32_LogicalDisk') {
                return $logicalDisk
            }
        }
        Mock Get-CimAssociatedInstance {
            param($Association)
            if ($Association -eq 'Win32_LogicalDiskToPartition') {
                return $partition
            }
            return [pscustomobject]@{ PNPDeviceID = 'SCSI\DISK0' }
        }
        Mock Get-PnpDeviceProperty { [pscustomobject]@{ Data = $null } }
        $script:testPnPUtilOutput = $InventoryOutput
        $script:testPnPUtilExitCode = $ExitCode
        function pnputil.exe {
            $global:LASTEXITCODE = $script:testPnPUtilExitCode
            $script:testPnPUtilOutput
        }

        try {
            { Get-WinUtilISOActiveStorageDriverMapping -Logger { param($message) $null = $message } } | Should -Throw $ExpectedError
        } finally {
            Remove-Item Function:\pnputil.exe -ErrorAction SilentlyContinue
        }
    }

    It "selects only uniquely resolved active packages" {
        . ([scriptblock]::Create($script:driverClassifierFunctions[2]))
        function Get-WinUtilISOActiveStorageDriverMapping {
            param([scriptblock]$Logger)
            $null = $Logger
            [pscustomobject]@{ PublishedInfName = 'oem10.inf'; OriginalInfName = 'storage.inf' }
        }

        $packages = @(
            [pscustomobject]@{ Directory = 'storage'; InfNames = @('storage.inf') },
            [pscustomobject]@{ Directory = 'network'; InfNames = @('network.inf') },
            [pscustomobject]@{ Directory = 'audio'; InfNames = @('audio.inf') }
        )

        $selected = @(Select-WinUtilISOWinPEDriverPackage -Packages $packages -Logger { param($message) $null = $message })
        $selected.Count | Should -Be 1
        $selected[0].Directory | Should -Be 'storage'
    }

    It "rejects missing and duplicate exported matches for an active OEM INF" -TestCases @(
        @{ Packages = @([pscustomobject]@{ Directory = 'other'; InfNames = @('other.inf') }); ExpectedError = '*no exported package directory contains it*' }
        @{ Packages = @([pscustomobject]@{ Directory = 'first'; InfNames = @('storage.inf') }, [pscustomobject]@{ Directory = 'second'; InfNames = @('storage.inf') }); ExpectedError = '*multiple exported package directories*' }
    ) {
        param($Packages, $ExpectedError)

        . ([scriptblock]::Create($script:driverClassifierFunctions[2]))
        function Get-WinUtilISOActiveStorageDriverMapping {
            param([scriptblock]$Logger)
            $null = $Logger
            [pscustomobject]@{ PublishedInfName = 'oem10.inf'; OriginalInfName = 'storage.inf' }
        }

        $packagesUnderTest = $Packages
        { Select-WinUtilISOWinPEDriverPackage -Packages $packagesUnderTest -Logger { param($message) $null = $message } } | Should -Throw $ExpectedError
    }

    It "completes the AMD RAID trio without selecting unrelated packages" {
        . ([scriptblock]::Create($script:driverClassifierFunctions[2]))
        function Get-WinUtilISOActiveStorageDriverMapping {
            param([scriptblock]$Logger)
            $null = $Logger
            [pscustomobject]@{ PublishedInfName = 'oem42.inf'; OriginalInfName = 'rcbottom.inf' }
        }

        $packages = @(
            [pscustomobject]@{ Directory = 'bottom'; InfNames = @('rcbottom.inf') },
            [pscustomobject]@{ Directory = 'raid'; InfNames = @('rcraid.inf') },
            [pscustomobject]@{ Directory = 'config'; InfNames = @('rccfg.inf') },
            [pscustomobject]@{ Directory = 'unrelated'; InfNames = @('network.inf') }
        )

        $selected = @(Select-WinUtilISOWinPEDriverPackage -Packages $packages -Logger { param($message) $null = $message })
        @($selected.Directory) | Should -HaveCount 3
        @($selected.Directory) | Should -Contain 'bottom'
        @($selected.Directory) | Should -Contain 'raid'
        @($selected.Directory) | Should -Contain 'config'
        @($selected.Directory) | Should -Not -Contain 'unrelated'
    }

    It "rejects missing or ambiguous AMD RAID dependencies" -TestCases @(
        @{
            Packages = @(
                [pscustomobject]@{ Directory = 'bottom'; InfNames = @('rcbottom.inf') },
                [pscustomobject]@{ Directory = 'config'; InfNames = @('rccfg.inf') }
            )
            ExpectedError = "*requires 'rcraid.inf'*"
        }
        @{
            Packages = @(
                [pscustomobject]@{ Directory = 'bottom'; InfNames = @('rcbottom.inf') },
                [pscustomobject]@{ Directory = 'raid-one'; InfNames = @('rcraid.inf') },
                [pscustomobject]@{ Directory = 'raid-two'; InfNames = @('rcraid.inf') },
                [pscustomobject]@{ Directory = 'config'; InfNames = @('rccfg.inf') }
            )
            ExpectedError = "*AMD RAID dependency 'rcraid.inf'*multiple exported package directories*"
        }
    ) {
        param($Packages, $ExpectedError)

        . ([scriptblock]::Create($script:driverClassifierFunctions[2]))
        function Get-WinUtilISOActiveStorageDriverMapping {
            param([scriptblock]$Logger)
            $null = $Logger
            [pscustomobject]@{ PublishedInfName = 'oem42.inf'; OriginalInfName = 'rcbottom.inf' }
        }

        $packagesUnderTest = $Packages
        { Select-WinUtilISOWinPEDriverPackage -Packages $packagesUnderTest -Logger { param($message) $null = $message } } | Should -Throw $ExpectedError
    }

    It "copies complete exported package directories for WinPE" {
        . ([scriptblock]::Create($script:driverClassifierFunctions[3]))
        $testRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilPackageCopy_$([guid]::NewGuid())"
        $source = Join-Path $testRoot 'source\storage-package'
        $destination = Join-Path $testRoot '$WinPEDriver$'

        try {
            New-Item -Path (Join-Path $source 'subdir') -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $source 'storage.inf') -Value 'inf' -Encoding ASCII
            Set-Content -Path (Join-Path $source 'storage.cat') -Value 'cat' -Encoding ASCII
            Set-Content -Path (Join-Path $source 'storage.sys') -Value 'sys' -Encoding ASCII
            Set-Content -Path (Join-Path $source 'subdir\coinstaller.dll') -Value 'dll' -Encoding ASCII

            $copiedPath = Copy-WinUtilISODriverPackage -Source $source -Destination $destination
            Test-Path (Join-Path $copiedPath 'storage.inf') | Should -BeTrue
            Test-Path (Join-Path $copiedPath 'storage.cat') | Should -BeTrue
            Test-Path (Join-Path $copiedPath 'storage.sys') | Should -BeTrue
            Test-Path (Join-Path $copiedPath 'subdir\coinstaller.dll') | Should -BeTrue
        } finally {
            Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "tracks every background ISO workflow with the shared busy state" {
        foreach ($functionText in @(
            $script:mountAndVerifyFunction,
            $script:modifyFunction,
            $script:cleanAndResetFunction,
            $script:exportFunction,
            $script:writeUsbFunction
        )) {
            $functionText | Should -Match ([regex]::Escape('$sync["Win11ISOProcessRunning"] = $true'))
            $functionText | Should -Match ([regex]::Escape('$sync["Win11ISOProcessRunning"] = $false'))
        }
    }

    It "uses setup-media completion wording" {
        $script:modifyFunction | Should -Match ([regex]::Escape('Setup media preparation complete. Choose an output option in Step 4.'))
        $script:modifyFunction | Should -Not -Match ([regex]::Escape('install.wim modification complete'))
    }

    It "runs ISO mount and verification outside the UI thread" {
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape("Invoke-WPFRunspace -ParameterList @(,('isoPath', `$isoPath))"))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('Invoke-WPFUIThread {'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('Write-WinUtilISOLog'))
        $script:mountAndVerifyFunction | Should -Not -Match ([regex]::Escape('Write-Win11ISOLog'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$sync["WPFWin11ISOBrowseButton"].IsEnabled = $false'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$sync["WPFWin11ISOBrowseButton"].IsEnabled = $true'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$sync["WPFWin11ISOMountButton"].IsEnabled = $false'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$sync["WPFWin11ISOMountButton"].IsEnabled = $true'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$sync["WPFWin11ISOModifyButton"].IsEnabled = $false'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$sync["WPFWin11ISOModifyButton"].IsEnabled = $true'))
    }

    It "blocks oversized install.esd before USB erase confirmation" {
        $script:writeUsbFunction | Should -Match ([regex]::Escape('$installEsd = Join-Path $contentsDir "sources\install.esd"'))
        $script:writeUsbFunction | Should -Match ([regex]::Escape('$esdSizeBytes -ge 4GB'))
        $script:writeUsbFunction | Should -Match 'install\.esd file'

        $guardIndex = $script:writeUsbFunction.IndexOf('$installEsd = Join-Path $contentsDir "sources\install.esd"')
        $confirmationIndex = $script:writeUsbFunction.IndexOf('Confirm USB Erase')
        $guardIndex | Should -BeGreaterThan -1
        $confirmationIndex | Should -BeGreaterThan $guardIndex
    }

    It "clears install.wim read-only attribute before FAT32 splitting" {
        $splitGuardIndex = $script:writeUsbFunction.IndexOf('$wimSizeMB -gt 3800')
        $readOnlyResetIndex = $script:writeUsbFunction.IndexOf(
            'Set-ItemProperty -LiteralPath $installWim -Name IsReadOnly -Value $false'
        )
        $splitCommandIndex = $script:writeUsbFunction.IndexOf('Split-WindowsImage')

        $splitGuardIndex | Should -BeGreaterThan -1
        $readOnlyResetIndex | Should -BeGreaterThan $splitGuardIndex
        $splitCommandIndex | Should -BeGreaterThan $readOnlyResetIndex
    }

    It "maps Windows edition names to setup edition IDs" {
        . ([scriptblock]::Create($script:editionIdFunction))

        $cases = @{
            "Windows 11 Home Single Language" = "CoreSingleLanguage"
            "Windows 11 Home N"               = "CoreN"
            "Windows 11 Home"                 = "Core"
            "Windows 11 Pro for Workstations N" = "ProfessionalWorkstationN"
            "Windows 11 Pro for Workstations" = "ProfessionalWorkstation"
            "Windows 11 Pro Education N"      = "ProfessionalEducationN"
            "Windows 11 Pro Education"        = "ProfessionalEducation"
            "Windows 11 Pro N"                = "ProfessionalN"
            "Windows 11 Pro"                  = "Professional"
            "Windows 11 Education N"          = "EducationN"
            "Windows 11 Education"            = "Education"
            "Windows 11 Enterprise LTSC N"    = "EnterpriseSN"
            "Windows 11 Enterprise LTSC"      = "EnterpriseS"
            "Windows 11 Enterprise N"         = "EnterpriseN"
            "Windows 11 Enterprise"           = "Enterprise"
        }

        foreach ($case in $cases.GetEnumerator()) {
            Get-WinUtilEditionIdFromName -EditionName $case.Key | Should -Be $case.Value
        }

        Get-WinUtilEditionIdFromName -EditionName "Windows 11 Unknown Edition" | Should -Be ""
    }

    It "writes ei.cfg and removes stale PID.txt for the selected edition" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoConfig_$([guid]::NewGuid())"
        $sourcesDir = Join-Path $contentRoot "sources"
        $logs = [System.Collections.Generic.List[string]]::new()
        $logger = { param($message) $logs.Add([string]$message) }

        try {
            New-Item -Path $sourcesDir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $sourcesDir "PID.txt") -Value "stale-key" -Encoding UTF8
            Set-Content -Path (Join-Path $sourcesDir "ei.cfg") -Value "stale-cfg" -Encoding UTF8

            . $script:isoScriptPath
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml (Get-Content -Path $script:autoUnattendPath -Raw) -InstallEditionId "Professional" -Log $logger

            Test-Path (Join-Path $sourcesDir "PID.txt") | Should -BeFalse
            Test-Path (Join-Path $sourcesDir "ei.cfg") | Should -BeTrue
            (Get-Content -Path (Join-Path $sourcesDir "ei.cfg")) -join "|" |
                Should -Be "[EditionID]|Professional|[Channel]|Retail|[VL]|0"
            ($logs -join "|") | Should -Match "Removed sources\\PID\.txt"
            ($logs -join "|") | Should -Match "Written sources\\ei\.cfg"
        } finally {
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "stages the complete WinUtil customization script and selected image index" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoAnswerFile_$([guid]::NewGuid())"
        $template = Get-Content -Path $script:autoUnattendPath -Raw

        try {
            New-Item -Path $contentRoot -ItemType Directory -Force | Out-Null
            . $script:isoScriptPath
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template -InstallEditionId "Core" -InstallImageIndex 6

            [xml]$answerFile = Get-Content -Path (Join-Path $contentRoot "autounattend.xml") -Raw
            $nsMgr = New-Object System.Xml.XmlNamespaceManager($answerFile.NameTable)
            $nsMgr.AddNamespace("u", "urn:schemas-microsoft-com:unattend")
            $nsMgr.AddNamespace("sg", "https://schneegans.de/windows/unattend-generator/")

            $answerFile.SelectSingleNode('/u:unattend/u:settings[@pass="windowsPE"]/u:component[@name="Microsoft-Windows-Setup"]/u:ImageInstall/u:OSImage/u:InstallFrom/u:MetaData[u:Key="/IMAGE/INDEX"]/u:Value', $nsMgr).InnerText | Should -Be '6'

            $postInstallFile = $answerFile.SelectSingleNode('//sg:File[@path="C:\Windows\Setup\Scripts\WinUtil-PostInstall.ps1"]', $nsMgr)
            $postInstallFile | Should -Not -BeNullOrEmpty
            $postInstallFile.InnerText | Should -Match 'Remove-AppxProvisionedPackage'
            $postInstallFile.InnerText | Should -Match 'DisableWindowsConsumerFeatures'
            $postInstallFile.InnerText | Should -Match 'Microsoft Compatibility Appraiser'
            $postInstallFile.InnerText | Should -Match 'OneDriveSetup.exe'
            $postInstallFile.InnerText | Should -Match 'function Set-WinUtilContentDeliveryManagerValues'
            $postInstallFile.InnerText | Should -Match ([regex]::Escape('Set-WinUtilContentDeliveryManagerValues $defaultHive'))
            $postInstallFile.InnerText | Should -Match ([regex]::Escape("Set-WinUtilContentDeliveryManagerValues 'HKCU'"))
            $postInstallFile.InnerText | Should -Match ([regex]::Escape("Set-WinUtilRegistryValue 'HKCU\Control Panel\UnsupportedHardwareNotificationCache' 'SV1'"))
            $postInstallFile.InnerText | Should -Match ([regex]::Escape("Set-WinUtilRegistryValue 'HKCU\Control Panel\UnsupportedHardwareNotificationCache' 'SV2'"))
            foreach ($defaultProfilePath in @(
                '$defaultHive\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo',
                '$defaultHive\Software\Microsoft\Windows\CurrentVersion\Privacy',
                '$defaultHive\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy',
                '$defaultHive\Software\Microsoft\Input\TIPC',
                '$defaultHive\Software\Microsoft\InputPersonalization',
                '$defaultHive\Software\Microsoft\InputPersonalization\TrainedDataStore',
                '$defaultHive\Software\Microsoft\Personalization\Settings'
            )) {
                $postInstallFile.InnerText | Should -Match ([regex]::Escape($defaultProfilePath))
            }

            $firstLogonFile = $answerFile.SelectSingleNode('//sg:File[@path="C:\Windows\Setup\Scripts\FirstLogon.ps1"]', $nsMgr)
            $firstLogonFile.InnerText | Should -Match 'WinUtil-PostInstall.ps1'

            $setupScriptsRoot = Join-Path $contentRoot 'sources\$OEM$\$$\Setup\Scripts'
            Test-Path (Join-Path $setupScriptsRoot 'Specialize.ps1') | Should -BeTrue
            Test-Path (Join-Path $setupScriptsRoot 'DefaultUser.ps1') | Should -BeTrue
            Test-Path (Join-Path $setupScriptsRoot 'FirstLogon.ps1') | Should -BeTrue
            Test-Path (Join-Path $setupScriptsRoot 'WinUtil-PostInstall.ps1') | Should -BeTrue
            Get-Content -Path (Join-Path $setupScriptsRoot 'FirstLogon.ps1') -Raw | Should -Match 'WinUtil-PostInstall.ps1'
            Get-Content -Path (Join-Path $setupScriptsRoot 'WinUtil-PostInstall.ps1') -Raw | Should -Match 'Remove-AppxProvisionedPackage'

            $tokens = $null
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseInput($postInstallFile.InnerText, [ref]$tokens, [ref]$errors) | Out-Null
            $errors.Count | Should -Be 0
        } finally {
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "stages the active storage package and services all exported drivers in one WIM lifecycle" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoDrivers_$([guid]::NewGuid())"
        $installWim = Join-Path $contentRoot 'sources\install.wim'
        $template = Get-Content -Path $script:autoUnattendPath -Raw
        $logs = [System.Collections.Generic.List[string]]::new()
        $script:dismCalls = [System.Collections.Generic.List[string]]::new()

        function dism.exe {
            param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments)

            $script:dismCalls.Add(($Arguments -join '|'))
            $global:LASTEXITCODE = 0
            if ($Arguments -contains '/Get-WimInfo') {
                'Languages : en-US'
                'Installation : Client'
                'Edition : Professional'
                'ProductSuite : Terminal Server'
                'ProductType : WinNT'
            } elseif ($Arguments -contains '/Mount-Image') {
                '[==========================100.0%==========================]'
            }
        }

        Mock Start-Process {
            param($FilePath, $ArgumentList)

            if ($FilePath -ne 'dism.exe') {
                throw "Unexpected process in driver export mock: $FilePath"
            }

            $destinationMatch = [regex]::Match([string]$ArgumentList, '/destination:"([^"]+)"')
            if (-not $destinationMatch.Success) {
                throw "Unable to find the mocked DISM export destination in: $ArgumentList"
            }

            $exportRoot = $destinationMatch.Groups[1].Value
            $fixtures = @(
                @{ Path = 'storage_pkg'; Name = 'iaStorAC.inf' },
                @{ Path = 'net_pkg'; Name = 'network.inf' }
            )

            foreach ($fixture in $fixtures) {
                $fixturePath = Join-Path $exportRoot $fixture.Path
                New-Item -Path $fixturePath -ItemType Directory -Force | Out-Null
                Set-Content -Path (Join-Path $fixturePath $fixture.Name) -Value '[Version]' -Encoding ASCII
                Set-Content -Path (Join-Path $fixturePath "$($fixture.Name).cat") -Value 'catalog' -Encoding ASCII
                Set-Content -Path (Join-Path $fixturePath "$($fixture.Name).sys") -Value 'binary' -Encoding ASCII
            }

            return [pscustomobject]@{ ExitCode = 0 }
        } -ParameterFilter { $FilePath -eq 'dism.exe' }

        $logicalDisk = New-CimInstance -ClassName Win32_LogicalDisk -ClientOnly -Property @{ DeviceID = $env:SystemDrive }
        $partition = New-CimInstance -ClassName Win32_DiskPartition -ClientOnly -Property @{ DeviceID = 'Disk #0, Partition #1' }
        Mock Get-CimInstance {
            param($ClassName)
            if ($ClassName -eq 'Win32_PnPSignedDriver') {
                return [pscustomobject]@{ DeviceID = 'SCSI\DISK0'; InfName = 'oem10.inf' }
            }
            if ($ClassName -eq 'Win32_LogicalDisk') {
                return $logicalDisk
            }
        }
        Mock Get-CimAssociatedInstance {
            param($Association)
            if ($Association -eq 'Win32_LogicalDiskToPartition') {
                return $partition
            }
            return [pscustomobject]@{ PNPDeviceID = 'SCSI\DISK0' }
        }
        Mock Get-PnpDeviceProperty { [pscustomobject]@{ Data = $null } }
        function pnputil.exe {
            $global:LASTEXITCODE = 0
            'DriverName,OriginalName,ProviderName'
            '"oem10.inf","iaStorAC.inf","Intel"'
        }

        try {
            New-Item -Path (Split-Path $installWim -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -Path $installWim -Value 'mock-wim'
            . $script:isoScriptPath
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template -InjectCurrentSystemDrivers $true -InstallImagePath $installWim -InstallImageIndex 6 -InstallEditionId 'Professional' -Log {
                param($message)
                $logs.Add([string]$message)
            }

            $winpeDriverRoot = Join-Path $contentRoot '$WinPEDriver$'
            @(Get-ChildItem -Path $winpeDriverRoot -Directory).Count | Should -Be 1
            Test-Path (Join-Path $winpeDriverRoot 'storage_pkg\iaStorAC.inf') | Should -BeTrue
            Test-Path (Join-Path $winpeDriverRoot 'storage_pkg\iaStorAC.inf.cat') | Should -BeTrue
            Test-Path (Join-Path $winpeDriverRoot 'storage_pkg\iaStorAC.inf.sys') | Should -BeTrue
            Test-Path (Join-Path $winpeDriverRoot 'net_pkg\network.inf') | Should -BeFalse

            @($script:dismCalls | Where-Object { $_ -match '/Mount-Image' }).Count | Should -Be 1
            @($script:dismCalls | Where-Object { $_ -match '/Add-Driver' }).Count | Should -Be 1
            @($script:dismCalls | Where-Object { $_ -match '/Unmount-Image\|.*\|/Commit' }).Count | Should -Be 1
            @($script:dismCalls | Where-Object { $_ -match '/Get-WimInfo' }).Count | Should -Be 2
            ($script:dismCalls -join "`n") | Should -Not -Match '/Cleanup-Image|/Export-Image'
            ($script:dismCalls | Where-Object { $_ -match '/Add-Driver' }) | Should -Match '/Driver:.*WinUtil_DriverExport_.*\|/Recurse'
            ($script:dismCalls | Where-Object { $_ -match '/Add-Driver' }) | Should -Not -Match '\$WinPEDriver\$'
            Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
                $FilePath -eq 'dism.exe' -and $ArgumentList -match '/online /export-driver /destination:'
            }

            [xml]$answerFile = Get-Content -Path (Join-Path $contentRoot 'autounattend.xml') -Raw
            $nsMgr = New-Object System.Xml.XmlNamespaceManager($answerFile.NameTable)
            $nsMgr.AddNamespace('sg', 'https://schneegans.de/windows/unattend-generator/')
            $answerFile.SelectSingleNode('//sg:File[@path="C:\Windows\Setup\Scripts\WinUtil-InstallDrivers.ps1"]', $nsMgr) | Should -BeNullOrEmpty
            ($logs -join '|') | Should -Match 'staged 1 active packages for WinPE'
            ($logs -join '|') | Should -Match 'install.wim metadata validation passed'
            ($logs -join '|') | Should -Match 'Driver export completed'
            ($logs -join '|') | Should -Match 'DISM mount completed'
            ($logs -join '|') | Should -Match 'DISM add-driver completed'
            ($logs -join '|') | Should -Match 'DISM commit completed'
            ($logs -join '|') | Should -Not -Match '100.0%'
        } finally {
            Remove-Item Function:\dism.exe -ErrorAction SilentlyContinue
            Remove-Item Function:\pnputil.exe -ErrorAction SilentlyContinue
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "preserves DISM export failure and no-INF cleanup semantics" -TestCases @(
        @{ ExitCode = 5; ExpectedError = '*dism.exe driver export failed with exit code 5*' }
        @{ ExitCode = 0; ExpectedError = '*DISM exported no driver INF files*' }
    ) {
        param($ExitCode, $ExpectedError)

        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoExportFailure_$([guid]::NewGuid())"
        $installWim = Join-Path $contentRoot 'sources\install.wim'
        $script:mockExportRoot = $null
        $script:mockExportExitCode = $ExitCode

        function dism.exe {
            $global:LASTEXITCODE = 0
        }
        Mock Start-Process {
            param($ArgumentList)
            $destinationMatch = [regex]::Match([string]$ArgumentList, '/destination:"([^"]+)"')
            $script:mockExportRoot = $destinationMatch.Groups[1].Value
            [pscustomobject]@{ ExitCode = $script:mockExportExitCode }
        } -ParameterFilter { $FilePath -eq 'dism.exe' }

        try {
            New-Item -Path (Split-Path $installWim -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -Path $installWim -Value 'mock-wim'
            . $script:isoScriptPath

            { Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml (Get-Content -Path $script:autoUnattendPath -Raw) -InjectCurrentSystemDrivers $true -InstallImagePath $installWim -InstallEditionId 'Professional' } |
                Should -Throw $ExpectedError

            $script:mockExportRoot | Should -Not -BeNullOrEmpty
            Test-Path -LiteralPath $script:mockExportRoot | Should -BeFalse
        } finally {
            Remove-Item Function:\dism.exe -ErrorAction SilentlyContinue
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "discards a partially mounted install.wim after mount failure" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoMountFailure_$([guid]::NewGuid())"
        $installWim = Join-Path $contentRoot 'sources\install.wim'
        $template = Get-Content -Path $script:autoUnattendPath -Raw
        $script:dismCalls = [System.Collections.Generic.List[string]]::new()

        function dism.exe {
            param([Parameter(ValueFromRemainingArguments)][string[]]$Arguments)

            $script:dismCalls.Add(($Arguments -join '|'))
            if ($Arguments -contains '/Get-WimInfo') {
                $global:LASTEXITCODE = 0
                'Languages : en-US'
                'Installation : Client'
                'Edition : Professional'
                'ProductSuite : Terminal Server'
                'ProductType : WinNT'
            } elseif ($Arguments -contains '/Mount-Image') {
                $global:LASTEXITCODE = 50
                'Mount failed'
            } elseif ($Arguments -contains '/Get-MountedImageInfo') {
                $global:LASTEXITCODE = 0
                "Mount Dir : $(Join-Path (Split-Path -Path $contentRoot -Parent) 'wim_mount')"
            } else {
                $global:LASTEXITCODE = 0
            }
        }

        Mock Start-Process {
            param($FilePath, $ArgumentList)

            if ($FilePath -ne 'dism.exe') {
                throw "Unexpected process in driver export mock: $FilePath"
            }

            $destinationMatch = [regex]::Match([string]$ArgumentList, '/destination:"([^"]+)"')
            $exportRoot = $destinationMatch.Groups[1].Value
            $fixturePath = Join-Path $exportRoot 'storage_pkg'
            New-Item -Path $fixturePath -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $fixturePath 'iaStorAC.inf') -Value "[Version]`r`nClass=System" -Encoding ASCII
            return [pscustomobject]@{ ExitCode = 0 }
        } -ParameterFilter { $FilePath -eq 'dism.exe' }

        $logicalDisk = New-CimInstance -ClassName Win32_LogicalDisk -ClientOnly -Property @{ DeviceID = $env:SystemDrive }
        $partition = New-CimInstance -ClassName Win32_DiskPartition -ClientOnly -Property @{ DeviceID = 'Disk #0, Partition #1' }
        Mock Get-CimInstance {
            param($ClassName)
            if ($ClassName -eq 'Win32_PnPSignedDriver') {
                return [pscustomobject]@{ DeviceID = 'SCSI\DISK0'; InfName = 'oem10.inf' }
            }
            if ($ClassName -eq 'Win32_LogicalDisk') {
                return $logicalDisk
            }
        }
        Mock Get-CimAssociatedInstance {
            param($Association)
            if ($Association -eq 'Win32_LogicalDiskToPartition') {
                return $partition
            }
            return [pscustomobject]@{ PNPDeviceID = 'SCSI\DISK0' }
        }
        Mock Get-PnpDeviceProperty { [pscustomobject]@{ Data = $null } }
        function pnputil.exe {
            $global:LASTEXITCODE = 0
            'DriverName,OriginalName,ProviderName'
            '"oem10.inf","iaStorAC.inf","Intel"'
        }

        try {
            New-Item -Path (Split-Path $installWim -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -Path $installWim -Value 'mock-wim'
            . $script:isoScriptPath

            { Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template -InjectCurrentSystemDrivers $true -InstallImagePath $installWim -InstallImageIndex 6 -InstallEditionId 'Professional' } |
                Should -Throw '*DISM mount failed*'

            @($script:dismCalls | Where-Object { $_ -match '/Get-MountedImageInfo' }).Count | Should -Be 1
            @($script:dismCalls | Where-Object { $_ -match '/Unmount-Image\|.*\|/Discard' }).Count | Should -Be 1
        } finally {
            Remove-Item Function:\dism.exe -ErrorAction SilentlyContinue
            Remove-Item Function:\pnputil.exe -ErrorAction SilentlyContinue
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "does not add driver setup artifacts when injection is disabled" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoNoDrivers_$([guid]::NewGuid())"

        try {
            New-Item -Path $contentRoot -ItemType Directory -Force | Out-Null
            . $script:isoScriptPath
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml (Get-Content -Path $script:autoUnattendPath -Raw) -InjectCurrentSystemDrivers $false -InstallEditionId 'Core'

            Test-Path (Join-Path $contentRoot '$WinPEDriver$') | Should -BeFalse
            [xml]$answerFile = Get-Content -Path (Join-Path $contentRoot 'autounattend.xml') -Raw
            $nsMgr = New-Object System.Xml.XmlNamespaceManager($answerFile.NameTable)
            $nsMgr.AddNamespace('sg', 'https://schneegans.de/windows/unattend-generator/')
            $answerFile.SelectSingleNode('//sg:File[@path="C:\Windows\Setup\Scripts\WinUtil-InstallDrivers.ps1"]', $nsMgr) | Should -BeNullOrEmpty
        } finally {
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "forces an existing UseConfigurationSet node to false" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoFallback_$([guid]::NewGuid())"

        try {
            New-Item -Path $contentRoot -ItemType Directory -Force | Out-Null
            [xml]$template = Get-Content -Path $script:autoUnattendPath -Raw
            $templateNs = New-Object System.Xml.XmlNamespaceManager($template.NameTable)
            $templateNs.AddNamespace('u', 'urn:schemas-microsoft-com:unattend')
            $template.SelectSingleNode('/u:unattend/u:settings[@pass="windowsPE"]/u:component[@name="Microsoft-Windows-Setup"]/u:UseConfigurationSet', $templateNs).InnerText = 'true'
            . $script:isoScriptPath
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template.OuterXml -InstallEditionId 'Core'

            [xml]$answerFile = Get-Content -Path (Join-Path $contentRoot 'autounattend.xml') -Raw
            $nsMgr = New-Object System.Xml.XmlNamespaceManager($answerFile.NameTable)
            $nsMgr.AddNamespace('u', 'urn:schemas-microsoft-com:unattend')

            $answerFile.SelectSingleNode('/u:unattend/u:settings[@pass="windowsPE"]/u:component[@name="Microsoft-Windows-Setup"]/u:UseConfigurationSet', $nsMgr).InnerText |
                Should -Be 'false'
            Test-Path (Join-Path $contentRoot 'sources\$OEM$\$$\Setup\Scripts\FirstLogon.ps1') | Should -BeTrue
        } finally {
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "leaves an absent UseConfigurationSet node absent" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoNoConfigurationSet_$([guid]::NewGuid())"

        try {
            New-Item -Path $contentRoot -ItemType Directory -Force | Out-Null
            [xml]$template = Get-Content -Path $script:autoUnattendPath -Raw
            $templateNs = New-Object System.Xml.XmlNamespaceManager($template.NameTable)
            $templateNs.AddNamespace('u', 'urn:schemas-microsoft-com:unattend')
            $configurationSetNode = $template.SelectSingleNode('/u:unattend/u:settings[@pass="windowsPE"]/u:component[@name="Microsoft-Windows-Setup"]/u:UseConfigurationSet', $templateNs)
            [void]$configurationSetNode.ParentNode.RemoveChild($configurationSetNode)

            . $script:isoScriptPath
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template.OuterXml -InstallEditionId 'Core'

            [xml]$answerFile = Get-Content -Path (Join-Path $contentRoot 'autounattend.xml') -Raw
            $nsMgr = New-Object System.Xml.XmlNamespaceManager($answerFile.NameTable)
            $nsMgr.AddNamespace('u', 'urn:schemas-microsoft-com:unattend')
            $answerFile.SelectSingleNode('/u:unattend/u:settings[@pass="windowsPE"]/u:component[@name="Microsoft-Windows-Setup"]/u:UseConfigurationSet', $nsMgr) |
                Should -BeNullOrEmpty
            $answerFile.OuterXml | Should -Not -Match '<UseConfigurationSet>true</UseConfigurationSet>'
        } finally {
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "attempts winget oscdimg install and exits before export when fallback fails" {
        $content = Get-Content -Path $script:isoWorkflowPath -Raw

        foreach ($expectedText in @(
            'oscdimg.exe not found. Attempting to install via winget...',
            'Install-WinUtilWinget',
            'Get-Command winget',
            'install -e --id Microsoft.OSCDIMG --accept-package-agreements --accept-source-agreements',
            'oscdimg.exe still not found after install attempt.',
            'oscdimg Not Found'
        )) {
            $content | Should -Match ([regex]::Escape($expectedText))
        }

        $fallbackIndex = $content.IndexOf('oscdimg.exe not found. Attempting to install via winget...')
        $notFoundDialogIndex = $content.IndexOf('oscdimg Not Found', $fallbackIndex)
        $runspaceIndex = $content.IndexOf('[Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()', $fallbackIndex)

        $fallbackIndex | Should -BeGreaterThan -1
        $notFoundDialogIndex | Should -BeGreaterThan $fallbackIndex
        $runspaceIndex | Should -BeGreaterThan $notFoundDialogIndex
    }
}
