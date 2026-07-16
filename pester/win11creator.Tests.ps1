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
        $script:addDriversFunction = Get-WinUtilFunctionText -Path $script:isoScriptPath -FunctionName "Add-DriversToImage"
        $script:answerFileChildElementFunction = Get-WinUtilFunctionText -Path $script:isoScriptPath -FunctionName "Get-WinUtilISOScriptChildElement"
        $script:answerFileConversionFunction = Get-WinUtilFunctionText -Path $script:isoScriptPath -FunctionName "ConvertTo-WinUtilISOAnswerFile"
        $script:editionConfigFunction = Get-WinUtilFunctionText -Path $script:isoScriptPath -FunctionName "Write-WinUtilISOEditionConfig"
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

    It "ISO script accepts selected edition setup metadata" {
        $isoScriptPath = Join-Path $PSScriptRoot "..\functions\private\Invoke-WinUtilISOScript.ps1"
        $content = Get-Content -Path $isoScriptPath -Raw

        foreach ($pattern in @(
            '\[string\]\$InstallEditionId',
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

    It "mounts the copied image file that was verified from the ISO" {
        foreach ($expectedText in @(
            '$sourceImageFileName = Split-Path $wimPath -Leaf',
            '$localWim = Join-Path $isoContents "sources\$sourceImageFileName"',
            'Copied ISO image file not found: sources\$sourceImageFileName'
        )) {
            $script:modifyFunction | Should -Match ([regex]::Escape($expectedText))
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

    It "writes ei.cfg and removes stale PID.txt for selected editions" {
        . ([scriptblock]::Create($script:editionConfigFunction))

        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoConfig_$([guid]::NewGuid())"
        $sourcesDir = Join-Path $contentRoot "sources"
        $logs = [System.Collections.Generic.List[string]]::new()
        $logger = { param($message) $logs.Add([string]$message) }

        try {
            New-Item -Path $sourcesDir -ItemType Directory -Force | Out-Null
            Set-Content -Path (Join-Path $sourcesDir "PID.txt") -Value "stale-key" -Encoding UTF8

            Write-WinUtilISOEditionConfig -ContentRoot $contentRoot -EditionId "Professional" -Logger $logger

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

    It "skips ei.cfg when selected edition ID is unknown" {
        . ([scriptblock]::Create($script:editionConfigFunction))

        $contentRoot = Join-Path ([IO.Path]::GetTempPath()) "WinUtilIsoConfig_$([guid]::NewGuid())"
        $logs = [System.Collections.Generic.List[string]]::new()
        $logger = { param($message) $logs.Add([string]$message) }

        try {
            New-Item -Path $contentRoot -ItemType Directory -Force | Out-Null

            Write-WinUtilISOEditionConfig -ContentRoot $contentRoot -EditionId "" -Logger $logger

            Test-Path (Join-Path $contentRoot "sources\ei.cfg") | Should -BeFalse
            ($logs -join "|") | Should -Match "selected edition ID is unknown"
        } finally {
            Remove-Item -Path $contentRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "converts autounattend setup metadata without preserving placeholder product keys" {
        . ([scriptblock]::Create($script:answerFileChildElementFunction))
        . ([scriptblock]::Create($script:answerFileConversionFunction))

        [xml]$templateXml = Get-Content -Path $script:autoUnattendPath -Raw
        $unattendNs = "urn:schemas-microsoft-com:unattend"
        $nsMgr = New-Object System.Xml.XmlNamespaceManager($templateXml.NameTable)
        $nsMgr.AddNamespace("u", $unattendNs)
        $nsMgr.AddNamespace("sg", "https://schneegans.de/windows/unattend-generator/")

        $setupComponent = $templateXml.SelectSingleNode('//u:settings[@pass="windowsPE"]/u:component[@name="Microsoft-Windows-Setup"]', $nsMgr)
        $userData = $templateXml.CreateElement("UserData", $unattendNs)
        $productKey = $templateXml.CreateElement("ProductKey", $unattendNs)
        $key = $templateXml.CreateElement("Key", $unattendNs)
        $key.InnerText = "00000-00000-00000-00000-00000"
        [void]$productKey.AppendChild($key)
        [void]$userData.AppendChild($productKey)
        [void]$setupComponent.AppendChild($userData)

        $originalSetupFileCount = $templateXml.SelectNodes("//sg:File", $nsMgr).Count
        [xml]$converted = ConvertTo-WinUtilISOAnswerFile -XmlContent $templateXml.OuterXml -ImageIndex 3
        $convertedNsMgr = New-Object System.Xml.XmlNamespaceManager($converted.NameTable)
        $convertedNsMgr.AddNamespace("u", $unattendNs)
        $convertedNsMgr.AddNamespace("sg", "https://schneegans.de/windows/unattend-generator/")

        $converted.DocumentElement.NamespaceURI | Should -Be $unattendNs
        $converted.DocumentElement.GetAttribute("xmlns:wcm") | Should -Be "http://schemas.microsoft.com/WMIConfig/2002/State"
        $converted.SelectNodes('//u:component[@name="Microsoft-Windows-Setup"]/u:UserData/u:ProductKey', $convertedNsMgr).Count | Should -Be 0
        $converted.SelectSingleNode('//u:ImageInstall/u:OSImage/u:InstallFrom/u:MetaData[u:Key="/IMAGE/INDEX"]/u:Value', $convertedNsMgr).InnerText | Should -Be "3"
        $converted.SelectNodes("//sg:File", $convertedNsMgr).Count | Should -Be $originalSetupFileCount
    }

    It "logs DISM output for driver injection through a mocked command" {
        . ([scriptblock]::Create($script:addDriversFunction))

        $script:dismArguments = @()
        function dism {
            param([Parameter(ValueFromRemainingArguments)]$Arguments)
            $script:dismArguments = @($Arguments)
            "driver one"
            "driver two"
        }

        $logs = [System.Collections.Generic.List[string]]::new()
        Add-DriversToImage -MountPath "C:\Mount" -DriverDir "C:\Drivers" -Label "install" -Logger {
            param($message)
            $logs.Add([string]$message)
        }

        ($script:dismArguments -join "|") | Should -Be "/English|/image:C:\Mount|/Add-Driver|/Driver:C:\Drivers|/Recurse"
        ($logs -join "|") | Should -Be "  dism[install]: driver one|  dism[install]: driver two"
    }

    It "keeps driver export and boot.wim injection behind the selected branch" {
        $content = Get-Content -Path $script:isoScriptPath -Raw

        foreach ($expectedText in @(
            'if ($InjectCurrentSystemDrivers)',
            'Export-WindowsDriver -Online -Destination $driverExportRoot',
            'Add-DriversToImage -MountPath $ScratchDir -DriverDir $driverExportRoot -Label "install" -Logger $Log',
            'Invoke-BootWimInject -BootWimPath $bootWim -DriverDir $driverExportRoot -Logger $Log',
            'Warning: boot.wim not found - skipping boot.wim driver injection.',
            'Driver injection skipped.'
        )) {
            $content | Should -Match ([regex]::Escape($expectedText))
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
