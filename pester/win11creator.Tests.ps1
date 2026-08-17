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

        $script:modifyFunction = Get-WinUtilFunctionText -Path $script:isoWorkflowPath -FunctionName "Invoke-WinUtilISOModify"
        $script:mountAndVerifyFunction = Get-WinUtilFunctionText -Path $script:isoWorkflowPath -FunctionName "Invoke-WinUtilISOMountAndVerify"
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
        $script:mountAndVerifyFunction | Should -Match ([regex]::Escape('$sync["WPFWin11ISOModifyButton"].IsEnabled = $true'))
    }

    It "reports ISO progress and logging through the shared helpers" {
        $content = Get-Content -Path $script:isoWorkflowPath -Raw
        $usbContent = Get-Content -Path $script:isoUsbWorkflowPath -Raw

        foreach ($source in @($content, $usbContent)) {
            $source | Should -Match ([regex]::Escape('Write-WinUtilJobProgress -Status'))
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
                @{ Path = 'system_pkg'; Name = 'chipset.inf'; Class = 'System' },
                @{ Path = 'storage_pkg'; Name = 'iaStorAC.inf'; Class = 'System' },
                @{ Path = 'scsi_pkg'; Name = 'controller.inf'; Class = 'SCSIAdapter' },
                @{ Path = 'net_pkg'; Name = 'network.inf'; Class = 'Net' },
                @{ Path = 'group_a\duplicate'; Name = 'audio.inf'; Class = 'Media' },
                @{ Path = 'group_b\duplicate'; Name = 'extension.inf'; Class = 'Extension' }
            )

            foreach ($fixture in $fixtures) {
                $fixturePath = Join-Path $exportRoot $fixture.Path
                New-Item -Path $fixturePath -ItemType Directory -Force | Out-Null
                Set-Content -Path (Join-Path $fixturePath $fixture.Name) -Value "[Version]`r`nClass=$($fixture.Class)" -Encoding ASCII
            }

            return [pscustomobject]@{ ExitCode = 0 }
        } -ParameterFilter { $FilePath -eq 'dism.exe' }

        try {
            New-Item -Path (Split-Path $installWim -Parent) -ItemType Directory -Force | Out-Null
            Set-Content -Path $installWim -Value 'mock-wim'
            . $script:isoScriptPath
            Invoke-WinUtilISOScript -ISOContentsDir $contentRoot -AutoUnattendXml $template -InjectCurrentSystemDrivers $true -InstallImagePath $installWim -InstallImageIndex 6 -InstallEditionId 'Professional' -Log {
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
            @($script:dismCalls | Where-Object { $_ -match '/Add-Driver' }).Count | Should -Be 1
            @($script:dismCalls | Where-Object { $_ -match '/Unmount-Image\|.*\|/Commit' }).Count | Should -Be 1
            @($script:dismCalls | Where-Object { $_ -match '/Get-WimInfo' }).Count | Should -Be 2
            ($script:dismCalls -join "`n") | Should -Not -Match '/Cleanup-Image|/Export-Image'

            [xml]$answerFile = Get-Content -Path (Join-Path $contentRoot 'autounattend.xml') -Raw
            $nsMgr = New-Object System.Xml.XmlNamespaceManager($answerFile.NameTable)
            $nsMgr.AddNamespace('sg', 'https://schneegans.de/windows/unattend-generator/')
            $answerFile.SelectSingleNode('//sg:File[@path="C:\Windows\Setup\Scripts\WinUtil-InstallDrivers.ps1"]', $nsMgr) | Should -BeNullOrEmpty
            ($logs -join '|') | Should -Match 'staged 2 boot-storage packages for WinPE'
            ($logs -join '|') | Should -Match 'install.wim metadata validation passed'
            ($logs -join '|') | Should -Match 'DISM mount completed.'
            ($logs -join '|') | Should -Not -Match '100.0%'
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

            $destinationMatch = [regex]::Match([string]$ArgumentList, '/destination:"([^"]+)"')
            $exportRoot = $destinationMatch.Groups[1].Value
            $fixturePath = Join-Path $exportRoot 'storage_pkg'
            New-Item -Path $fixturePath -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $fixturePath 'iaStorAC.inf') -Value "[Version]`r`nClass=System" -Encoding ASCII
            return [pscustomobject]@{ ExitCode = 0 }
        } -ParameterFilter { $FilePath -eq 'dism.exe' }

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
            'install -e --id Microsoft.OSCDIMG --accept-package-agreements --accept-source-agreements',
            'oscdimg.exe still not found after install attempt.',
            'oscdimg Not Found'
        )) {
            $content | Should -Match ([regex]::Escape($expectedText))
        }

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
