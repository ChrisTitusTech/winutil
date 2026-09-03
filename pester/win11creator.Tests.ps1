#===========================================================================
# Tests - Win11 Creator

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

        # Root package folders the fixture below yields, once nested_pkg\x64 is folded into
        # its parent. Written out rather than derived, so a broken dedup fails the assertions
        # instead of quietly moving the expectation with it.
        $script:expectedRootPackages = 8
        $script:resilienceDriverFixtures = @(
            @{ Path = 'system_pkg'; Name = 'chipset.inf'; Class = 'System' },
            @{ Path = 'storage_pkg'; Name = 'iaStorAC.inf'; Class = 'System' },
            @{ Path = 'scsi_pkg'; Name = 'controller.inf'; Class = 'SCSIAdapter' },
            @{ Path = 'net_pkg'; Name = 'network.inf'; Class = 'Net' },
            @{ Path = 'group_a\duplicate'; Name = 'audio.inf'; Class = 'Media' },
            @{ Path = 'group_b\duplicate'; Name = 'extension.inf'; Class = 'Media' },
            @{ Path = 'nested_pkg'; Name = 'main.inf'; Class = 'Net' },
            @{ Path = 'nested_pkg\x64'; Name = 'extra.inf'; Class = 'Net' },
            @{ Path = 'net_pkg_v2'; Name = 'network2.inf'; Class = 'Net' }
        )

        # Stands in for `dism /Online /Export-Driver`, which the ISO script now invokes
        # through Invoke-WinUtilISODism rather than Start-Process. The two `duplicate` leaf
        # names cover per-package failure logging, which must stay unambiguous; `nested_pkg`
        # covers a package holding INFs at its root and in a subfolder; and `net_pkg_v2` is a
        # sibling whose name starts with `net_pkg`, which the dedup must not swallow.
        function Export-WinUtilTestDriverPackage {
            param (
                [Parameter(Mandatory)][string[]]$Arguments,
                [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Fixtures
            )

            $destination = @($Arguments | Where-Object { $_ -like '/Destination:*' })
            if ($destination.Count -ne 1) {
                throw "Expected exactly one /Destination argument in the mocked DISM export: $($Arguments -join ' ')"
            }

            $exportRoot = $destination[0].Substring('/Destination:'.Length)
            $script:driverExportRoot = $exportRoot

            # .NET file APIs rather than the cmdlets: Set-Content's -Encoding comes from the
            # FileSystem provider, and a wildcard character in $exportRoot stops the provider
            # resolving, so the parameter disappears.
            foreach ($fixture in $fixtures) {
                $fixturePath = Join-Path $exportRoot $fixture.Path
                [void][System.IO.Directory]::CreateDirectory($fixturePath)
                [System.IO.File]::WriteAllText(
                    (Join-Path $fixturePath $fixture.Name),
                    (@(
                        '[Version]'
                        "Class=$($fixture.Class)"
                        if ($fixture.Provider) { "Provider=$($fixture.Provider)" }
                        if ($fixture.DriverVer) {
                            $versionKeyword = if ($fixture.VersionKeyword) { $fixture.VersionKeyword } else { 'DriverVer' }
                            "$versionKeyword=$($fixture.DriverVer)"
                        }
                    ) -join "`r`n"),
                    [System.Text.Encoding]::ASCII)
            }
        }

        function New-WinUtilDriverExportHarness {
            param (
                [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Fixtures,
                [string]$FailedDriverPath,
                [switch]$FailAllAddDrivers,
                [switch]$FailDiscard
            )

            $script:dismCalls = [System.Collections.Generic.List[string]]::new()
            $script:driverExportRoot = $null
            $script:driverExportFixtures = $Fixtures
            $script:failedDriverPath = $FailedDriverPath
            $script:failAllAddDrivers = $FailAllAddDrivers
            $script:failDiscard = $FailDiscard
            $script:exportedInfsAtAddDriver = $null

            Set-Item -Path function:global:dism.exe -Value {
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
                } elseif ($Arguments -contains '/Export-Driver') {
                    Export-WinUtilTestDriverPackage -Arguments $Arguments -Fixtures $script:driverExportFixtures
                } elseif ($Arguments -contains '/Add-Driver') {
                    # Snapshot what's still on disk right as DISM would /Recurse over it: this is the
                    # only point excluded folders are provably gone, since the SUT wipes the whole
                    # export root in its own cleanup once Invoke-WinUtilISOScript returns.
                    $script:exportRootAtAddDriver = @(Get-ChildItem -LiteralPath $script:driverExportRoot -Directory -Recurse -ErrorAction SilentlyContinue | ForEach-Object FullName)
                    $script:exportedInfsAtAddDriver = @(Get-ChildItem -LiteralPath $script:driverExportRoot -Filter '*.inf' -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object FullName)
                    if ($script:failAllAddDrivers -or ($script:failedDriverPath -and @($Arguments | Where-Object { $_ -like "*$($script:failedDriverPath)" }).Count -gt 0)) {
                        $global:LASTEXITCODE = 13
                        'Error: 13'
                    }
                } elseif ($Arguments -contains '/Discard' -and $script:failDiscard) {
                    $global:LASTEXITCODE = 50
                    'Discard failed'
                }
            }
        }

        $script:modifyFunction = Get-WinUtilFunctionText -Path $script:isoWorkflowPath -FunctionName "Invoke-WinUtilISOModify"
        $script:mountAndVerifyFunction = Get-WinUtilFunctionText -Path $script:isoWorkflowPath -FunctionName "Invoke-WinUtilISOMountAndVerify"
        $script:checkExistingWorkFunction = Get-WinUtilFunctionText -Path $script:isoWorkflowPath -FunctionName "Invoke-WinUtilISOCheckExistingWork"
        $script:cleanAndResetFunction = Get-WinUtilFunctionText -Path $script:isoWorkflowPath -FunctionName "Invoke-WinUtilISOCleanAndReset"
        $script:exportFunction = Get-WinUtilFunctionText -Path $script:isoWorkflowPath -FunctionName "Invoke-WinUtilISOExport"
        $script:writeUsbFunction = Get-WinUtilFunctionText -Path $script:isoUsbWorkflowPath -FunctionName "Invoke-WinUtilISOWriteUSB"
        $script:editionIdFunction = Get-WinUtilFunctionText -Path $script:isoWorkflowPath -FunctionName "Get-WinUtilEditionIdFromName"
        $script:wimMetadataAssertionFunction = Get-WinUtilFunctionText -Path $script:isoScriptPath -FunctionName "Assert-WinUtilISOWimMetadata"
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
            '$workDir = "$($workDir)_$(([guid]::NewGuid()).ToString(''N'').Substring(0, 8))"'
        )) {
            $script:modifyFunction | Should -Match ([regex]::Escape($expectedText))
        }

        $script:modifyFunction | Should -Not -Match ([regex]::Escape("Reusing existing temp directory"))
    }

    It "turns ISO-script warning messages into job warnings" {
        $script:modifyFunction | Should -Match 'if \(\$m -like "Warning:\*"\)[\s\S]*Write-WinUtilISOLog -Level "WARN" -Message \$m -SkipSessionLog[\s\S]*Write-Warning \$m'
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

    It "stages only boot-storage drivers in WinPE" {
        $isoScriptContent = Get-Content -Path $script:isoScriptPath -Raw

        $isoScriptContent | Should -Match ([regex]::Escape("Join-Path `$ContentRoot '`$WinpeDriver$'"))
        $isoScriptContent | Should -Match 'SCSIAdapter\|HDC'
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

    It "runs every background ISO workflow through the shared job layer" {
        $jobNames = @{
            mountAndVerify = "ISO mount"
            modify         = "ISO modify"
            cleanAndReset  = "ISO cleanup"
            export         = "ISO export"
            writeUsb       = "USB write"
        }

        foreach ($entry in @(
            @{ Text = $script:mountAndVerifyFunction; Name = $jobNames.mountAndVerify },
            @{ Text = $script:modifyFunction; Name = $jobNames.modify },
            @{ Text = $script:cleanAndResetFunction; Name = $jobNames.cleanAndReset },
            @{ Text = $script:exportFunction; Name = $jobNames.export },
            @{ Text = $script:writeUsbFunction; Name = $jobNames.writeUsb }
        )) {
            $entry.Text | Should -Match ([regex]::Escape("Start-WinUtilJob -Name `"$($entry.Name)`""))
            # The job layer owns the busy state, the progress bar, and the taskbar item
            $entry.Text | Should -Not -Match ([regex]::Escape('Win11ISOProcessRunning'))
            $entry.Text | Should -Not -Match ([regex]::Escape('RunspaceFactory]::CreateRunspace()'))
            $entry.Text | Should -Not -Match ([regex]::Escape('SessionStateProxy.SetVariable'))
            $entry.Text | Should -Not -Match ([regex]::Escape('[System.Windows.MessageBox]::Show'))
        }
    }

    It "runs ISO mount and verification outside the UI thread" {
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('Start-WinUtilJob -Name "ISO mount"'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('IsoPath = $isoPath'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('Invoke-WPFUIThread -ScriptBlock {'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('Write-WinUtilISOLog'))
        $script:mountAndVerifyFunction | Should -Not -Match ([regex]::Escape('Write-Win11ISOLog'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$sync["WPFWin11ISOBrowseButton"].IsEnabled = $false'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$sync["WPFWin11ISOBrowseButton"].IsEnabled = $true'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$sync["WPFWin11ISOMountButton"].IsEnabled = $false'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$sync["WPFWin11ISOMountButton"].IsEnabled = $true'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$sync["WPFWin11ISOModifyButton"].IsEnabled = $false'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$sync["WPFWin11ISOModifyButton"].IsEnabled = [bool]$Verified'))
    }

    It "dismounts an ISO and keeps modification disabled when verification fails" {
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$verified = $false'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$verified = $true'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('Dismount-DiskImage -ImagePath $isoPath -ErrorAction Stop'))
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$sync["Win11ISOImagePath"] = $null'))
        $script:mountAndVerifyFunction.IndexOf('Dismount-DiskImage') | Should -BeGreaterThan $script:mountAndVerifyFunction.IndexOf('finally')
    }

    It "keeps ISO cleanup in finally so stopping modification cannot bypass it" {
        $finallyIndex = $script:modifyFunction.IndexOf('finally')

        $finallyIndex | Should -BeGreaterThan -1
        $script:modifyFunction.IndexOf('Dismount-DiskImage', $finallyIndex) | Should -BeGreaterThan $finallyIndex
        $script:modifyFunction.IndexOf('Remove-Item -Path $workDir -Recurse -Force', $finallyIndex) | Should -BeGreaterThan $finallyIndex
        $script:modifyFunction.IndexOf('$sync["Win11ISOImagePath"] = $null', $finallyIndex) | Should -BeGreaterThan $finallyIndex
    }

    It "retries existing-work discovery after the active job finishes" {
        $script:checkExistingWorkFunction | Should -Match ([regex]::Escape('Invoke-WinUtilWhenIdle -DelayMilliseconds 500'))
        $script:checkExistingWorkFunction | Should -Match ([regex]::Escape('Invoke-WinUtilISOCheckExistingWork'))
        $script:checkExistingWorkFunction | Should -Match ([regex]::Escape('$sync["Win11ISOExistingWorkRetryPending"] = $false'))
    }

    It "reports ISO progress and logging through the shared helpers" {
        $content = Get-Content -Path $script:isoWorkflowPath -Raw
        $usbContent = Get-Content -Path $script:isoUsbWorkflowPath -Raw

        foreach ($source in @($content, $usbContent)) {
            $source | Should -Match ([regex]::Escape('Step-WinUtilJob -Status'))
            $source | Should -Not -Match '(?m)^\s*function (Log|SetProgress)\('
            $source | Should -Not -Match ([regex]::Escape('$sync["WPFTweaksProgressLabel"]'))
        }

        # Every status-log line also lands in the session log
        $content | Should -Match ([regex]::Escape('Write-WinUtilLog -Level $Level -Component "Win11Creator" -Message $Message'))
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



    It "stages storage drivers for WinPE and adds all drivers to one install.wim index" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoDrivers_$([guid]::NewGuid())"
        $installWim = Join-Path $contentRoot 'sources\install.wim'
        $template = Get-Content -Path $script:autoUnattendPath -Raw
        $logs = [System.Collections.Generic.List[string]]::new()

        New-WinUtilDriverExportHarness -Fixtures @(
            @{ Path = 'system_pkg'; Name = 'chipset.inf'; Class = 'System' },
            @{ Path = 'storage_pkg'; Name = 'iaStorAC.inf'; Class = 'System' },
            @{ Path = 'scsi_pkg'; Name = 'controller.inf'; Class = 'SCSIAdapter' },
            @{ Path = 'net_pkg'; Name = 'network.inf'; Class = 'Net' },
            @{ Path = 'group_a\duplicate'; Name = 'audio.inf'; Class = 'Media' },
            @{ Path = 'hdx_asusext_apot_g5-tse.inf_amd64_aabbccddeeff0011'; Name = 'hdx_asusext_apot_g5-tse.inf'; Class = 'Extension' },
            @{ Path = 'ntprint.inf_x86_7426e1b60aa62272'; Name = 'ntprint.inf'; Class = 'Printer'; DriverVer = '1/1/2023,10.0.26100.8875' },
            @{ Path = 'ntprint.inf_x86_58e7118cdecb935e'; Name = 'ntprint.inf'; Class = 'Printer'; DriverVer = '6/1/2024,10.0.26100.9168' },
            @{ Path = 'nested_pkg'; Name = 'main.inf'; Class = 'Net' },
            @{ Path = 'nested_pkg\x64'; Name = 'extra.inf'; Class = 'Net' },
            @{ Path = 'net_pkg_v2'; Name = 'network2.inf'; Class = 'Net' }
        )

        try {
            New-Item -Path (Split-Path $installWim -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -Path $installWim -Value 'mock-wim'
            . $script:isoScriptPath
            $driversInjected = [ref]$false
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template -InjectCurrentSystemDrivers $true -InstallImagePath $installWim -InstallImageIndex 6 -InstallEditionId 'Professional' -DriversInjected $driversInjected -Log {
                param($message)
                $logs.Add([string]$message)
            }

            $winpeDriverRoot = Join-Path $contentRoot '$WinpeDriver$'
            @(Get-ChildItem -Path $winpeDriverRoot -Directory).Count | Should -Be 2
            Test-Path (Join-Path $winpeDriverRoot 'system_pkg\chipset.inf') | Should -BeFalse
            Test-Path (Join-Path $winpeDriverRoot 'storage_pkg\iaStorAC.inf') | Should -BeTrue
            Test-Path (Join-Path $winpeDriverRoot 'scsi_pkg\controller.inf') | Should -BeTrue
            Test-Path (Join-Path $winpeDriverRoot 'net_pkg\network.inf') | Should -BeFalse

            @($script:dismCalls | Where-Object { $_ -match '/Mount-Image' }).Count | Should -Be 1
            @($script:dismCalls | Where-Object { $_ -match '/Add-Driver' }).Count | Should -Be $script:expectedRootPackages
            @($script:dismCalls | Where-Object { $_ -match '/Unmount-Image\|.*\|/Commit' }).Count | Should -Be 1
            @($script:dismCalls | Where-Object { $_ -match '/Get-WimInfo' }).Count | Should -Be 2
            ($script:dismCalls -join "`n") | Should -Not -Match '/Cleanup-Image|/Export-Image'
            ($logs -join '|') | Should -Match "Added $script:expectedRootPackages of $script:expectedRootPackages driver packages"

            # nested_pkg holds INFs at its root and under x64. The root add already recurses
            # into x64, so the subfolder must not get an /Add-Driver call of its own.
            @($script:dismCalls | Where-Object { $_ -match '/Add-Driver' -and $_ -match ([regex]::Escape('nested_pkg')) }).Count | Should -Be 1
            ($script:dismCalls -join "`n") | Should -Not -Match ([regex]::Escape('nested_pkg\x64'))

            [xml]$answerFile = Get-Content -Path (Join-Path $contentRoot 'autounattend.xml') -Raw
            $nsMgr = New-Object System.Xml.XmlNamespaceManager($answerFile.NameTable)
            $nsMgr.AddNamespace('sg', 'https://schneegans.de/windows/unattend-generator/')
            $answerFile.SelectSingleNode('//sg:File[@path="C:\Windows\Setup\Scripts\WinUtil-InstallDrivers.ps1"]', $nsMgr) | Should -BeNullOrEmpty
            ($logs -join '|') | Should -Match 'Exported 9 of 11 driver packages \(2 staged for WinPE, 2 excluded\)'
            ($logs -join '|') | Should -Match "Excluding extension-class driver package '.*hdx_asusext_apot_g5-tse.*'"
            ($logs -join '|') | Should -Match "Excluding stale duplicate driver package '.*ntprint\.inf_x86_7426e1b60aa62272' \(DriverVer 1/1/2023,10\.0\.26100\.8875\) superseded by '.*ntprint\.inf_x86_58e7118cdecb935e' \(DriverVer 6/1/2024,10\.0\.26100\.9168\)"
            ($logs -join '|') | Should -Match 'install.wim metadata validation passed'
            ($logs -join '|') | Should -Match 'DISM mount completed.'
            ($logs -join '|') | Should -Not -Match '100.0%'

            $script:exportRootAtAddDriver | Should -Not -Contain (Join-Path $script:driverExportRoot 'hdx_asusext_apot_g5-tse.inf_amd64_aabbccddeeff0011')
            $script:exportRootAtAddDriver | Should -Not -Contain (Join-Path $script:driverExportRoot 'ntprint.inf_x86_7426e1b60aa62272')
            $script:exportRootAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'ntprint.inf_x86_58e7118cdecb935e')
            $script:exportRootAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'system_pkg')
            $script:exportRootAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'group_a\duplicate')
        } finally {
            Remove-Item Function:\dism.exe -ErrorAction SilentlyContinue
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "excludes Class=Extension driver packages from Add-Driver regardless of vendor or case" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoExtensionExclude_$([guid]::NewGuid())"
        $installWim = Join-Path $contentRoot 'sources\install.wim'
        $template = Get-Content -Path $script:autoUnattendPath -Raw
        $logs = [System.Collections.Generic.List[string]]::new()

        New-WinUtilDriverExportHarness -Fixtures @(
            @{ Path = 'net_pkg'; Name = 'network.inf'; Class = 'Net' },
            @{ Path = 'ext_pkg_lower'; Name = 'lowercase_extension.inf'; Class = 'extension' },
            @{ Path = 'ext_pkg_quoted'; Name = 'quoted_extension.inf'; Class = '"Extension"' }
        )

        try {
            New-Item -Path (Split-Path $installWim -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -Path $installWim -Value 'mock-wim'
            . $script:isoScriptPath
            $driversInjected = [ref]$false
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template -InjectCurrentSystemDrivers $true -InstallImagePath $installWim -InstallImageIndex 6 -InstallEditionId 'Professional' -DriversInjected $driversInjected -Log {
                param($message)
                $logs.Add([string]$message)
            }

            @($script:dismCalls | Where-Object { $_ -match '/Add-Driver' }).Count | Should -Be 1
            ($logs -join '|') | Should -Match 'Exported 1 of 3 driver packages \(0 staged for WinPE, 2 excluded\)'
            ($logs -join '|') | Should -Match "Excluding extension-class driver package '.*ext_pkg_lower'"
            ($logs -join '|') | Should -Match "Excluding extension-class driver package '.*ext_pkg_quoted'"
            ($logs -join '|') | Should -Not -Match "Excluding extension-class driver package '.*net_pkg'"
            $driversInjected.Value | Should -BeTrue

            $script:exportRootAtAddDriver | Should -Not -Contain (Join-Path $script:driverExportRoot 'ext_pkg_lower')
            $script:exportRootAtAddDriver | Should -Not -Contain (Join-Path $script:driverExportRoot 'ext_pkg_quoted')
            $script:exportRootAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'net_pkg')
        } finally {
            Remove-Item Function:\dism.exe -ErrorAction SilentlyContinue
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "preserves a retained nested package when its parent package is excluded" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoNestedRetained_$([guid]::NewGuid())"
        $installWim = Join-Path $contentRoot 'sources\install.wim'
        $template = Get-Content -Path $script:autoUnattendPath -Raw
        $logs = [System.Collections.Generic.List[string]]::new()

        New-WinUtilDriverExportHarness -Fixtures @(
            @{ Path = 'parent_pkg'; Name = 'extension.inf'; Class = 'Extension' },
            @{ Path = 'parent_pkg\retained_child'; Name = 'network.inf'; Class = 'Net' }
        )

        try {
            New-Item -Path (Split-Path $installWim -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -Path $installWim -Value 'mock-wim'
            . $script:isoScriptPath
            $driversInjected = [ref]$false
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template -InjectCurrentSystemDrivers $true -InstallImagePath $installWim -InstallImageIndex 6 -InstallEditionId 'Professional' -DriversInjected $driversInjected -Log {
                param($message)
                $logs.Add([string]$message)
            }

            $addDriverCalls = @($script:dismCalls | Where-Object { $_ -match '/Add-Driver' })
            $addDriverCalls.Count | Should -Be 1
            $addDriverCalls[0] | Should -Match ([regex]::Escape('parent_pkg\retained_child'))
            $script:exportRootAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'parent_pkg')
            $script:exportRootAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'parent_pkg\retained_child')
            $script:exportedInfsAtAddDriver | Should -Not -Contain (Join-Path $script:driverExportRoot 'parent_pkg\extension.inf')
            $script:exportedInfsAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'parent_pkg\retained_child\network.inf')
            ($logs -join '|') | Should -Match "Keeping excluded driver package directory '.*parent_pkg' because it contains a retained nested package"
            $driversInjected.Value | Should -BeTrue
        } finally {
            Remove-Item Function:\dism.exe -ErrorAction SilentlyContinue
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "removes an excluded nested INF before recursively adding its retained ancestor" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoNestedExcluded_$([guid]::NewGuid())"
        $installWim = Join-Path $contentRoot 'sources\install.wim'
        $template = Get-Content -Path $script:autoUnattendPath -Raw

        New-WinUtilDriverExportHarness -Fixtures @(
            @{ Path = 'root_pkg'; Name = 'root.inf'; Class = 'Net' },
            @{ Path = 'root_pkg\excluded_child'; Name = 'extension.inf'; Class = 'Extension' },
            @{ Path = 'root_pkg\excluded_child\retained_grandchild'; Name = 'storage.inf'; Class = 'SCSIAdapter' }
        )

        try {
            New-Item -Path (Split-Path $installWim -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -Path $installWim -Value 'mock-wim'
            . $script:isoScriptPath
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template -InjectCurrentSystemDrivers $true -InstallImagePath $installWim -InstallImageIndex 6 -InstallEditionId 'Professional'

            $addDriverCalls = @($script:dismCalls | Where-Object { $_ -match '/Add-Driver' })
            $addDriverCalls.Count | Should -Be 1
            $addDriverCalls[0] | Should -Match ([regex]::Escape('/Driver:' + (Join-Path $script:driverExportRoot 'root_pkg')))
            $script:exportRootAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'root_pkg\excluded_child')
            $script:exportRootAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'root_pkg\excluded_child\retained_grandchild')
            $script:exportedInfsAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'root_pkg\root.inf')
            $script:exportedInfsAtAddDriver | Should -Not -Contain (Join-Path $script:driverExportRoot 'root_pkg\excluded_child\extension.inf')
            $script:exportedInfsAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'root_pkg\excluded_child\retained_grandchild\storage.inf')
        } finally {
            Remove-Item Function:\dism.exe -ErrorAction SilentlyContinue
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "validates WIM metadata and reports no injection when every package is excluded" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoAllExcluded_$([guid]::NewGuid())"
        $installWim = Join-Path $contentRoot 'sources\install.wim'
        $template = Get-Content -Path $script:autoUnattendPath -Raw
        $logs = [System.Collections.Generic.List[string]]::new()

        New-WinUtilDriverExportHarness -Fixtures @(
            @{ Path = 'ext_pkg_a'; Name = 'a.inf'; Class = 'Extension' },
            @{ Path = 'ext_pkg_b'; Name = 'b.inf'; Class = 'Extension' }
        )

        try {
            New-Item -Path (Split-Path $installWim -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -Path $installWim -Value 'mock-wim'
            . $script:isoScriptPath
            $driversInjected = [ref]$true
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template -InjectCurrentSystemDrivers $true -InstallImagePath $installWim -InstallImageIndex 6 -InstallEditionId 'Professional' -DriversInjected $driversInjected -Log {
                param($message)
                $logs.Add([string]$message)
            }

            $driversInjected.Value | Should -BeFalse
            ($logs -join '|') | Should -Match 'No drivers found to inject: every exported package was excluded'
            @($script:dismCalls | Where-Object { $_ -match '/Get-WimInfo' }).Count | Should -Be 1
            @($script:dismCalls | Where-Object { $_ -match '/Mount-Image' }).Count | Should -Be 0
            @($script:dismCalls | Where-Object { $_ -match '/Add-Driver' }).Count | Should -Be 0
        } finally {
            Remove-Item Function:\dism.exe -ErrorAction SilentlyContinue
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "keeps packages from different providers even when the INF name and architecture match" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoProviderCollision_$([guid]::NewGuid())"
        $installWim = Join-Path $contentRoot 'sources\install.wim'
        $template = Get-Content -Path $script:autoUnattendPath -Raw
        $logs = [System.Collections.Generic.List[string]]::new()

        New-WinUtilDriverExportHarness -Fixtures @(
            @{ Path = 'device.inf_amd64_11111111aaaaaaaa'; Name = 'device.inf'; Class = 'Net'; Provider = 'Contoso'; DriverVer = '1/1/2023,1.0.0.0' },
            @{ Path = 'device.inf_amd64_22222222bbbbbbbb'; Name = 'device.inf'; Class = 'Net'; Provider = 'Fabrikam'; DriverVer = '1/1/2024,2.0.0.0' }
        )

        try {
            New-Item -Path (Split-Path $installWim -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -Path $installWim -Value 'mock-wim'
            . $script:isoScriptPath
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template -InjectCurrentSystemDrivers $true -InstallImagePath $installWim -InstallImageIndex 6 -InstallEditionId 'Professional' -Log {
                param($message)
                $logs.Add([string]$message)
            }

            @($script:dismCalls | Where-Object { $_ -match '/Add-Driver' }).Count | Should -Be 2
            ($logs -join '|') | Should -Match 'Exported 2 of 2 driver packages \(0 staged for WinPE, 0 excluded\)'
            ($logs -join '|') | Should -Not -Match 'Excluding stale duplicate driver package'

            $script:exportRootAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'device.inf_amd64_11111111aaaaaaaa')
            $script:exportRootAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'device.inf_amd64_22222222bbbbbbbb')
        } finally {
            Remove-Item Function:\dism.exe -ErrorAction SilentlyContinue
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "drops stale duplicate driver versions and keeps only the highest DriverVer" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoStaleDedup_$([guid]::NewGuid())"
        $installWim = Join-Path $contentRoot 'sources\install.wim'
        $template = Get-Content -Path $script:autoUnattendPath -Raw
        $logs = [System.Collections.Generic.List[string]]::new()

        New-WinUtilDriverExportHarness -Fixtures @(
            # Three-way duplicate mirroring the real ntprint.inf report: only the newest DriverVer should survive.
            @{ Path = 'ntprint.inf_x86_7426e1b60aa62272'; Name = 'ntprint.inf'; Class = 'Printer'; DriverVer = '1/1/2023,10.0.26100.8875' },
            @{ Path = 'ntprint.inf_x86_6688e7b66f8d9fb5'; Name = 'ntprint.inf'; Class = 'Printer'; DriverVer = '1/1/2024,10.0.26100.8972' },
            @{ Path = 'ntprint.inf_x86_58e7118cdecb935e'; Name = 'ntprint.inf'; Class = 'Printer'; DriverVer = '6/1/2024,10.0.26100.9168' },
            # A duplicate pair where one package is missing DriverVer entirely: the parseable one must win.
            @{ Path = 'sample.inf_amd64_11111111aaaaaaaa'; Name = 'sample.inf'; Class = 'Net' },
            @{ Path = 'sample.inf_amd64_22222222bbbbbbbb'; Name = 'sample.inf'; Class = 'Net'; DriverVer = '3/1/2024,1.2.3.4' },
            # A duplicate pair keyed entirely on case-insensitive DriverVer parsing: the uppercase
            # DRIVERVER on the newer package must still be read and win the comparison.
            @{ Path = 'caps.inf_amd64_33333333cccccccc'; Name = 'caps.inf'; Class = 'Net'; DriverVer = '1/1/2020,1.0.0.0'; VersionKeyword = 'driverver' },
            @{ Path = 'caps.inf_amd64_44444444dddddddd'; Name = 'caps.inf'; Class = 'Net'; DriverVer = '1/1/2021,2.0.0.0'; VersionKeyword = 'DRIVERVER' }
        )

        try {
            New-Item -Path (Split-Path $installWim -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -Path $installWim -Value 'mock-wim'
            . $script:isoScriptPath
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template -InjectCurrentSystemDrivers $true -InstallImagePath $installWim -InstallImageIndex 6 -InstallEditionId 'Professional' -Log {
                param($message)
                $logs.Add([string]$message)
            }

            @($script:dismCalls | Where-Object { $_ -match '/Add-Driver' }).Count | Should -Be 3
            ($logs -join '|') | Should -Match 'Exported 3 of 7 driver packages \(0 staged for WinPE, 4 excluded\)'
            ($logs -join '|') | Should -Match "Excluding stale duplicate driver package '.*ntprint\.inf_x86_7426e1b60aa62272' \(DriverVer 1/1/2023,10\.0\.26100\.8875\) superseded by '.*ntprint\.inf_x86_58e7118cdecb935e'"
            ($logs -join '|') | Should -Match "Excluding stale duplicate driver package '.*ntprint\.inf_x86_6688e7b66f8d9fb5' \(DriverVer 1/1/2024,10\.0\.26100\.8972\) superseded by '.*ntprint\.inf_x86_58e7118cdecb935e'"
            ($logs -join '|') | Should -Match "Excluding stale duplicate driver package '.*sample\.inf_amd64_11111111aaaaaaaa' \(DriverVer unknown\) superseded by '.*sample\.inf_amd64_22222222bbbbbbbb' \(DriverVer 3/1/2024,1\.2\.3\.4\)"
            ($logs -join '|') | Should -Match "Excluding stale duplicate driver package '.*caps\.inf_amd64_33333333cccccccc' \(DriverVer 1/1/2020,1\.0\.0\.0\) superseded by '.*caps\.inf_amd64_44444444dddddddd' \(DriverVer 1/1/2021,2\.0\.0\.0\)"

            $script:exportRootAtAddDriver | Should -Not -Contain (Join-Path $script:driverExportRoot 'ntprint.inf_x86_7426e1b60aa62272')
            $script:exportRootAtAddDriver | Should -Not -Contain (Join-Path $script:driverExportRoot 'ntprint.inf_x86_6688e7b66f8d9fb5')
            $script:exportRootAtAddDriver | Should -Not -Contain (Join-Path $script:driverExportRoot 'sample.inf_amd64_11111111aaaaaaaa')
            $script:exportRootAtAddDriver | Should -Not -Contain (Join-Path $script:driverExportRoot 'caps.inf_amd64_33333333cccccccc')
            $script:exportRootAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'ntprint.inf_x86_58e7118cdecb935e')
            $script:exportRootAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'sample.inf_amd64_22222222bbbbbbbb')
            $script:exportRootAtAddDriver | Should -Contain (Join-Path $script:driverExportRoot 'caps.inf_amd64_44444444dddddddd')
        } finally {
            Remove-Item Function:\dism.exe -ErrorAction SilentlyContinue
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "discards partial changes and commits the remaining drivers when one package fails to add" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoDriverPartial_$([guid]::NewGuid())"
        $installWim = Join-Path $contentRoot 'sources\install.wim'
        $template = Get-Content -Path $script:autoUnattendPath -Raw
        $logs = [System.Collections.Generic.List[string]]::new()
        New-WinUtilDriverExportHarness -Fixtures $script:resilienceDriverFixtures -FailedDriverPath 'group_a\duplicate'

        try {
            New-Item -Path (Split-Path $installWim -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -Path $installWim -Value 'mock-wim'
            . $script:isoScriptPath
            $driversInjected = [ref]$false
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template -InjectCurrentSystemDrivers $true -InstallImagePath $installWim -InstallImageIndex 6 -InstallEditionId 'Professional' -DriversInjected $driversInjected -Log {
                param($message)
                $logs.Add([string]$message)
            }

            @($script:dismCalls | Where-Object { $_ -match '/Mount-Image' }).Count | Should -Be 2
            @($script:dismCalls | Where-Object { $_ -match '/Unmount-Image\|.*\|/Commit' }).Count | Should -Be 1
            @($script:dismCalls | Where-Object { $_ -match '/Unmount-Image\|.*\|/Discard' }).Count | Should -Be 1

            $lastMountCall = $script:dismCalls | Where-Object { $_ -match '/Mount-Image' } | Select-Object -Last 1
            $lastMountIndex = [Array]::LastIndexOf($script:dismCalls.ToArray(), $lastMountCall)
            $finalMountCalls = @($script:dismCalls[($lastMountIndex + 1)..($script:dismCalls.Count - 1)])
            @($finalMountCalls | Where-Object { $_ -match '/Add-Driver' }).Count | Should -Be ($script:expectedRootPackages - 1)
            ($finalMountCalls -join "`n") | Should -Not -Match ([regex]::Escape('group_a\duplicate'))

            ($logs -join '|') | Should -Match "Added $($script:expectedRootPackages - 1) of $script:expectedRootPackages driver packages"
            ($logs -join '|') | Should -Match 'install.wim metadata validation passed'
            # group_a and group_b share a leaf name, so the warning must name the failing
            # package by its subpath; a leaf-only name would read 'duplicate' and be ambiguous.
            ($logs -join '|') | Should -Match ([regex]::Escape("failed to add driver package 'group_a\duplicate'"))
            ($logs -join '|') | Should -Match ([regex]::Escape('add-driver:group_b\duplicate completed'))
            $driversInjected.Value | Should -BeTrue
        } finally {
            Remove-Item Function:\dism.exe -ErrorAction SilentlyContinue
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "discards the mount and keeps going when every driver package fails to add" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoDriverAllFail_$([guid]::NewGuid())"
        $installWim = Join-Path $contentRoot 'sources\install.wim'
        $template = Get-Content -Path $script:autoUnattendPath -Raw
        $logs = [System.Collections.Generic.List[string]]::new()
        New-WinUtilDriverExportHarness -Fixtures $script:resilienceDriverFixtures -FailAllAddDrivers

        try {
            New-Item -Path (Split-Path $installWim -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -Path $installWim -Value 'mock-wim'
            . $script:isoScriptPath
            $driversInjected = [ref]$true
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template -InjectCurrentSystemDrivers $true -InstallImagePath $installWim -InstallImageIndex 6 -InstallEditionId 'Professional' -DriversInjected $driversInjected -Log {
                param($message)
                $logs.Add([string]$message)
            }

            @($script:dismCalls | Where-Object { $_ -match '/Add-Driver' }).Count | Should -Be $script:expectedRootPackages
            @($script:dismCalls | Where-Object { $_ -match '/Unmount-Image\|.*\|/Commit' }).Count | Should -Be 0
            @($script:dismCalls | Where-Object { $_ -match '/Mount-Image' }).Count | Should -Be $script:expectedRootPackages
            @($script:dismCalls | Where-Object { $_ -match '/Unmount-Image\|.*\|/Discard' }).Count | Should -Be $script:expectedRootPackages
            @($script:dismCalls | Where-Object { $_ -match '/Get-WimInfo' }).Count | Should -Be 1

            ($logs -join '|') | Should -Match "none of the $script:expectedRootPackages exported driver packages could be added"
            ($logs -join '|') | Should -Not -Match "Added 0 of $script:expectedRootPackages"
            # WinPE staging is independent of WIM servicing, so it must survive the failure.
            @(Get-ChildItem -Path (Join-Path $contentRoot '$WinpeDriver$') -Directory).Count | Should -Be 2
            $driversInjected.Value | Should -BeFalse
        } finally {
            Remove-Item Function:\dism.exe -ErrorAction SilentlyContinue
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "finds exported drivers when the temp path contains wildcard characters" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoDriverGlob_$([guid]::NewGuid())"
        $installWim = Join-Path $contentRoot 'sources\install.wim'
        $template = Get-Content -Path $script:autoUnattendPath -Raw
        $logs = [System.Collections.Generic.List[string]]::new()
        New-WinUtilDriverExportHarness -Fixtures $script:resilienceDriverFixtures

        # A Windows account named like "John [Work]" puts wildcard characters in %TEMP%.
        # Get-ChildItem -Path would glob them, find nothing, and abort the whole ISO run.
        $originalTemp = $env:TEMP
        $bracketTemp = Join-Path ([IO.Path]::GetTempPath()) "WinUtil [Glob] $([guid]::NewGuid())"

        try {
            New-Item -Path (Split-Path $installWim -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -Path $installWim -Value 'mock-wim'
            New-Item -Path $bracketTemp -ItemType Directory -Force | Out-Null
            $env:TEMP = $bracketTemp
            . $script:isoScriptPath
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template -InjectCurrentSystemDrivers $true -InstallImagePath $installWim -InstallImageIndex 6 -InstallEditionId 'Professional' -Log {
                param($message)
                $logs.Add([string]$message)
            }

            ($logs -join '|') | Should -Match "Added $script:expectedRootPackages of $script:expectedRootPackages driver packages"
            @($script:dismCalls | Where-Object { $_ -match '/Unmount-Image\|.*\|/Commit' }).Count | Should -Be 1
            ($logs -join '|') | Should -Match ([regex]::Escape('add-driver:nested_pkg completed'))
        } finally {
            $env:TEMP = $originalTemp
            Remove-Item Function:\dism.exe -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $bracketTemp -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "stops when a potentially partial mount cannot be discarded after a package fails" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoDriverDiscardFailure_$([guid]::NewGuid())"
        $installWim = Join-Path $contentRoot 'sources\install.wim'
        $template = Get-Content -Path $script:autoUnattendPath -Raw
        New-WinUtilDriverExportHarness -Fixtures $script:resilienceDriverFixtures -FailAllAddDrivers -FailDiscard

        try {
            New-Item -Path (Split-Path $installWim -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -Path $installWim -Value 'mock-wim'
            . $script:isoScriptPath

            { Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template -InjectCurrentSystemDrivers $true -InstallImagePath $installWim -InstallImageIndex 6 -InstallEditionId 'Professional' } |
                Should -Throw '*Failed to discard the potentially partial install.wim mount after driver package*'

            @($script:dismCalls | Where-Object { $_ -match '/Unmount-Image\|.*\|/Discard' }).Count | Should -Be 2
            @($script:dismCalls | Where-Object { $_ -match '/Unmount-Image\|.*\|/Commit' }).Count | Should -Be 0
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
            } elseif ($Arguments -contains '/Export-Driver') {
                $global:LASTEXITCODE = 0
                Export-WinUtilTestDriverPackage -Arguments $Arguments -Fixtures @(
                    @{ Path = 'storage_pkg'; Name = 'iaStorAC.inf'; Class = 'System' }
                )
            } else {
                $global:LASTEXITCODE = 0
            }
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
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "does not add driver setup artifacts when injection is disabled" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoNoDrivers_$([guid]::NewGuid())"

        try {
            New-Item -Path $contentRoot -ItemType Directory -Force | Out-Null
            . $script:isoScriptPath
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml (Get-Content -Path $script:autoUnattendPath -Raw) -InjectCurrentSystemDrivers $false -InstallEditionId 'Core'

            Test-Path (Join-Path $contentRoot '$WinpeDriver$') | Should -BeFalse
            [xml]$answerFile = Get-Content -Path (Join-Path $contentRoot 'autounattend.xml') -Raw
            $nsMgr = New-Object System.Xml.XmlNamespaceManager($answerFile.NameTable)
            $nsMgr.AddNamespace('sg', 'https://schneegans.de/windows/unattend-generator/')
            $answerFile.SelectSingleNode('//sg:File[@path="C:\Windows\Setup\Scripts\WinUtil-InstallDrivers.ps1"]', $nsMgr) | Should -BeNullOrEmpty
        } finally {
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "enables configuration-set fallback when staging OEM setup scripts" {
        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoFallback_$([guid]::NewGuid())"

        try {
            New-Item -Path $contentRoot -ItemType Directory -Force | Out-Null
            . $script:isoScriptPath
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml (Get-Content -Path $script:autoUnattendPath -Raw) -InstallEditionId 'Core'

            [xml]$answerFile = Get-Content -Path (Join-Path $contentRoot 'autounattend.xml') -Raw
            $nsMgr = New-Object System.Xml.XmlNamespaceManager($answerFile.NameTable)
            $nsMgr.AddNamespace('u', 'urn:schemas-microsoft-com:unattend')

            $answerFile.SelectSingleNode('/u:unattend/u:settings[@pass="windowsPE"]/u:component[@name="Microsoft-Windows-Setup"]/u:UseConfigurationSet', $nsMgr).InnerText |
                Should -Be 'true'
            Test-Path (Join-Path $contentRoot 'sources\$OEM$\$$\Setup\Scripts\FirstLogon.ps1') | Should -BeTrue
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
            '$env:ProgramFiles\WinGet\Packages',
            '$env:ProgramFiles\WinGet\Links\oscdimg.exe',
            'install -e --id Microsoft.OSCDIMG --accept-package-agreements --accept-source-agreements',
            'oscdimg.exe still not found after install attempt.',
            'oscdimg Not Found'
        )) {
            $content | Should -Match ([regex]::Escape($expectedText))
        }

        ([regex]::Matches($content, 'function Get-WinUtilOscdimgPath', 'IgnoreCase')).Count | Should -Be 1
        $content | Should -Match ([regex]::Escape('Write-WinUtilISOLog -Level "WARN" -Message "oscdimg.exe still not found after install attempt."'))

        # The export job stops at the dialog instead of running oscdimg without a binary
        $exportOscdimgIndex = $script:exportFunction.IndexOf('$oscdimg = Get-WinUtilOscdimgPath')
        $exportDialogIndex = $script:exportFunction.IndexOf('oscdimg Not Found', $exportOscdimgIndex)
        $exportRunIndex = $script:exportFunction.IndexOf('Running oscdimg...', $exportOscdimgIndex)

        $exportOscdimgIndex | Should -BeGreaterThan -1
        $exportDialogIndex | Should -BeGreaterThan $exportOscdimgIndex
        $exportRunIndex | Should -BeGreaterThan $exportDialogIndex
        $script:exportFunction | Should -Match ([regex]::Escape('return'))
    }
}
