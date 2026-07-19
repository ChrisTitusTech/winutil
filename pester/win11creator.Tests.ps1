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

    It "tracks every background ISO workflow with the shared busy state" {
        foreach ($functionText in @(
            $script:modifyFunction,
            $script:cleanAndResetFunction,
            $script:exportFunction,
            $script:writeUsbFunction
        )) {
            $functionText | Should -Match ([regex]::Escape('$sync["Win11ISOProcessRunning"] = $true'))
            $functionText | Should -Match ([regex]::Escape('$sync["Win11ISOProcessRunning"] = $false'))
        }
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
