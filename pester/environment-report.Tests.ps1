#===========================================================================
# Tests - Environment Report
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Write-WinUtilLog.ps1")
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilToggleStatus.ps1")
    . (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilCurrentSystem.ps1")
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilTweaksStateReport.ps1")
    . (Join-Path $script:repoRoot "functions\private\Test-WinUtilPackageManager.ps1")
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilEnvironmentReport.ps1")
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilEnvironmentReportLogsPath.ps1")
    . (Join-Path $script:repoRoot "functions\private\Write-WinUtilEnvironmentReportExport.ps1")
}

Describe "Get-WinUtilEnvironmentReport" {
    BeforeEach {
        # Keep this Describe focused on the top-level schema; tweaksState grouping/detection has
        # its own dedicated Describe below with its own registry fixture.
        Mock Get-WinUtilTweaksStateReport {
            [pscustomobject]@{
                collectionStatus = "collected"
                essentialTweaks = [pscustomobject]@{}
                customizePreferences = [pscustomobject]@{}
                advancedTweaks = [pscustomobject]@{}
                performancePlans = [pscustomobject]@{}
                notEvaluable = @()
            }
        }

        Mock Get-CimInstance {
            switch ($ClassName) {
                "Win32_OperatingSystem" {
                    return [pscustomobject]@{
                        Caption = "Windows 11 Pro"
                        Version = "10.0.26100"
                        BuildNumber = "26100"
                        OSArchitecture = "64-bit"
                        TotalVisibleMemorySize = 16777216
                    }
                }
                "Win32_Processor" {
                    return [pscustomobject]@{
                        Name = "Example CPU"
                        NumberOfLogicalProcessors = 8
                    }
                }
            }
        }
        Mock Get-ExecutionPolicy { "RemoteSigned" }
        Mock Test-WinUtilPackageManager { "not-installed" }
        Mock Test-Path { $false }
        Mock Get-ItemProperty { $null }
        Mock Write-WinUtilLog { }
        Mock Write-Warning { }
    }

    It "returns the versioned allowlisted report schema" {
        $report = Get-WinUtilEnvironmentReport

        $report.schemaVersion | Should -Be "1.0"
        $report.generatedAtUtc | Should -Match '^\d{4}-\d{2}-\d{2}T'
        $report.windows.edition | Should -Be "Windows 11 Pro"
        $report.hardware.cpuModel | Should -Be "Example CPU"
        $report.hardware.logicalProcessorCount | Should -Be 8
        $report.hardware.totalMemoryGB | Should -Be 16
        $report.powershell.PSObject.Properties.Name | Should -Be @("edition", "version", "executionPolicy")
        $report.powershell.executionPolicy | Should -Be "RemoteSigned"
        $report.packageManagers.PSObject.Properties.Name | Should -Be @("winget", "chocolatey")
        $report.system.PSObject.Properties.Name | Should -Be @("pendingRebootRequired")
        $report.PSObject.Properties.Name | Should -Not -Contain "windowsFeatures"
        $report.PSObject.Properties.Name | Should -Contain "tweaksState"
    }

    It "contains no fields outside the approved report schema" {
        # Exact property-name assertions, not a blocklist of specific bad names - a blocklist only
        # catches fields someone thought to list, and would miss e.g. a future "biosUuid" or "userSid".
        # Dynamic tweak keys inside tweaksState's groups are intentionally not asserted here.
        $report = Get-WinUtilEnvironmentReport

        $report.PSObject.Properties.Name | Should -Be @(
            "schemaVersion", "generatedAtUtc", "windows", "hardware", "powershell",
            "packageManagers", "system", "tweaksState"
        )
        $report.windows.PSObject.Properties.Name | Should -Be @("edition", "version", "buildNumber", "architecture")
        $report.hardware.PSObject.Properties.Name | Should -Be @("cpuModel", "logicalProcessorCount", "totalMemoryGB")
        $report.packageManagers.winget.PSObject.Properties.Name | Should -Be @("installed", "version")
        $report.packageManagers.chocolatey.PSObject.Properties.Name | Should -Be @("installed", "version")
        $report.tweaksState.PSObject.Properties.Name | Should -Be @(
            "collectionStatus", "essentialTweaks", "customizePreferences", "advancedTweaks",
            "performancePlans", "notEvaluable"
        )
    }

    It "does not report a package manager as installed unless Test-WinUtilPackageManager confirms it" {
        $report = Get-WinUtilEnvironmentReport

        $report.packageManagers.winget.installed | Should -BeFalse
        $report.packageManagers.winget.version | Should -BeNullOrEmpty
        $report.packageManagers.chocolatey.installed | Should -BeFalse
        $report.packageManagers.chocolatey.version | Should -BeNullOrEmpty
    }

    It "reads a package manager's version via its own -v flag once installed is confirmed" {
        Mock Test-WinUtilPackageManager { "installed" } -ParameterFilter { $winget }
        Mock winget { "v1.29.290" }

        $report = Get-WinUtilEnvironmentReport

        $report.packageManagers.winget.installed | Should -BeTrue
        $report.packageManagers.winget.version | Should -Be "v1.29.290"
    }

    It "does not treat a failed package-manager probe message as a version" {
        Mock Test-WinUtilPackageManager { "installed" } -ParameterFilter { $winget }
        Mock winget {
            $global:LASTEXITCODE = 7
            "WinGet failed to initialize"
        }

        $report = Get-WinUtilEnvironmentReport

        $report.packageManagers.winget.installed | Should -BeTrue
        $report.packageManagers.winget.version | Should -BeNullOrEmpty
        Should -Invoke Write-WinUtilLog -ParameterFilter {
            $Level -eq "WARN" -and $Message -like "Failed to read WinGet version:*code 7*"
        }
        Should -Invoke Write-Warning -ParameterFilter {
            $Message -like "Failed to read WinGet version:*code 7*"
        }
    }

    It "surfaces an incomplete tweak-state report as a warning" {
        Mock Get-WinUtilTweaksStateReport {
            [pscustomobject]@{ collectionStatus = "unavailable" }
        }

        Get-WinUtilEnvironmentReport | Out-Null

        Should -Invoke Write-Warning -ParameterFilter {
            $Message -eq "Failed to collect the complete tweak state for the environment report."
        }
    }

    It "flags a pending reboot from PendingFileRenameOperations" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ PendingFileRenameOperations = @("a", "b") }
        }

        $report = Get-WinUtilEnvironmentReport

        $report.system.pendingRebootRequired | Should -BeTrue
    }

    It "does not flag a pending reboot for a present but empty PendingFileRenameOperations value" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ PendingFileRenameOperations = @() }
        }

        $report = Get-WinUtilEnvironmentReport

        $report.system.pendingRebootRequired | Should -BeFalse
    }

    It "reports pending reboot state as unknown when a registry read fails" {
        Mock Get-ItemProperty { throw "registry access denied" }

        $report = Get-WinUtilEnvironmentReport

        $report.system.pendingRebootRequired | Should -BeNullOrEmpty
        Should -Invoke Write-Warning -ParameterFilter {
            $Message -like "Failed to check pending-reboot registry state:*registry access denied*"
        }
    }

}

Describe "Get-WinUtilEnvironmentReportLogsPath" {
    It "swaps the JSON extension for a _logs.txt suffix" {
        Get-WinUtilEnvironmentReportLogsPath -JsonPath "C:\Reports\WinUtilEnvironmentReport_20260101.json" |
            Should -Be "C:\Reports\WinUtilEnvironmentReport_20260101_logs.txt"
    }

    It "handles a path with no extension" {
        Get-WinUtilEnvironmentReportLogsPath -JsonPath "C:\Reports\Report" |
            Should -Be "C:\Reports\Report_logs.txt"
    }
}

Describe "Invoke-WPFExportEnvironmentReport overwrite protection" {
    It "checks the derived logs path literally" {
        $source = Get-Content -LiteralPath (Join-Path $script:repoRoot "functions\public\Invoke-WPFExportEnvironmentReport.ps1") -Raw

        $source | Should -Match 'Test-Path\s+-LiteralPath\s+\$logsPath'
    }

    It "aborts rather than retaining a stale companion when logs are excluded" {
        $source = Get-Content -LiteralPath (Join-Path $script:repoRoot "functions\public\Invoke-WPFExportEnvironmentReport.ps1") -Raw

        $source | Should -Match 'if \(-not \$includeLogs\) \{[\s\S]*Choose another report filename[\s\S]*return'
        $source | Should -Match 'if \(-not \$replaceLogs\) \{\s*return\s*\}'
    }
}

Describe "Write-WinUtilEnvironmentReportExport" {
    BeforeEach {
        $script:rollbackJsonPath = $null
        $script:removeAttempts = [System.Collections.Generic.List[string]]::new()
    }

    It "restores the previous JSON when publishing the log companion fails" {
        $jsonPath = Join-Path $TestDrive "report.json"
        $logsPath = Join-Path $TestDrive "report_logs.txt"
        [System.IO.File]::WriteAllText($jsonPath, "old report")
        $null = New-Item -ItemType Directory -Path $logsPath

        {
            Write-WinUtilEnvironmentReportExport -JsonPath $jsonPath -Json "new report" `
                -LogsPath $logsPath -Logs "new logs" -IncludeLogs
        } | Should -Throw

        [System.IO.File]::ReadAllText($jsonPath) | Should -Be "old report"
        [System.IO.Directory]::Exists($logsPath) | Should -BeTrue
        @(Get-ChildItem -LiteralPath $TestDrive -File).Name | Should -Be @("report.json")
    }

    It "retains the recovery copy and still attempts log rollback when JSON restore fails" {
        $jsonPath = Join-Path $TestDrive "rollback-report.json"
        $logsPath = Join-Path $TestDrive "rollback-report_logs.txt"
        [System.IO.File]::WriteAllText($jsonPath, "old report")
        $null = New-Item -ItemType Directory -Path $logsPath
        $script:rollbackJsonPath = $jsonPath
        Mock Copy-WinUtilEnvironmentReportExportFile {
            if ($SourcePath -like "*.bak" -and $DestinationPath -eq $script:rollbackJsonPath) {
                throw "JSON restore blocked"
            }
            [System.IO.File]::Copy($SourcePath, $DestinationPath, [bool]$Overwrite)
        }

        {
            Write-WinUtilEnvironmentReportExport -JsonPath $jsonPath -Json "new report" `
                -LogsPath $logsPath -Logs "new logs" -IncludeLogs
        } | Should -Throw "*Recovery copy retained*"

        [System.IO.File]::ReadAllText($jsonPath) | Should -Be "new report"
        $backup = @(Get-ChildItem -LiteralPath $TestDrive -Filter "rollback-report.json.*.bak" -File)
        $backup.Count | Should -Be 1
        [System.IO.File]::ReadAllText($backup[0].FullName) | Should -Be "old report"
        [System.IO.Directory]::Exists($logsPath) | Should -BeTrue
    }

    It "does not let one temporary-file cleanup failure mask a successful export" {
        $jsonPath = Join-Path $TestDrive "cleanup-report.json"
        $logsPath = Join-Path $TestDrive "cleanup-report_logs.txt"
        Mock Remove-WinUtilEnvironmentReportExportFile {
            $script:removeAttempts.Add($Path)
            if ($Path -like "$jsonPath.*.tmp") {
                throw "temporary file is locked"
            }
            [System.IO.File]::Delete($Path)
        }

        {
            Write-WinUtilEnvironmentReportExport -JsonPath $jsonPath -Json "new report" `
                -LogsPath $logsPath -Logs "new logs" -IncludeLogs
        } | Should -Not -Throw

        [System.IO.File]::ReadAllText($jsonPath) | Should -Be "new report"
        [System.IO.File]::ReadAllText($logsPath) | Should -Be "new logs"
        @($script:removeAttempts | Where-Object { $_ -like "*.tmp" }).Count | Should -Be 2
    }
}

Describe "Get-WinUtilTweaksStateReport" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            configs = @{
                tweaks = [pscustomobject]@{
                    WPFTweaksApplied     = [pscustomobject]@{
                        category = "Essential Tweaks"
                        registry = @([pscustomobject]@{ Path = "HKCU:\Fake1"; Name = "Enabled"; Value = "1"; OriginalValue = "0"; DefaultState = "true" })
                    }
                    WPFTweaksNotApplied  = [pscustomobject]@{
                        category = "Essential Tweaks"
                        registry = @([pscustomobject]@{ Path = "HKCU:\Fake2"; Name = "Enabled"; Value = "1"; OriginalValue = "0"; DefaultState = "false" })
                    }
                    WPFToggleCustomize   = [pscustomobject]@{
                        category = "Customize Preferences"
                        Type     = "Toggle"
                        registry = @([pscustomobject]@{ Path = "HKCU:\Fake3"; Name = "Enabled"; Value = "1"; OriginalValue = "0"; DefaultState = "true" })
                    }
                    WPFTweaksAdvanced    = [pscustomobject]@{
                        category = "z__Advanced Tweaks - CAUTION"
                        registry = @([pscustomobject]@{ Path = "HKCU:\Fake4"; Name = "Enabled"; Value = "1"; OriginalValue = "0"; DefaultState = "false" })
                    }
                    WPFComboExample      = [pscustomobject]@{
                        category = "Customize Preferences"
                        Type     = "Combobox"
                    }
                    WPFButtonExample     = [pscustomobject]@{
                        category = "z__Advanced Tweaks - CAUTION"
                        Type     = "Button"
                    }
                    WPFScriptOnly        = [pscustomobject]@{
                        category = "Essential Tweaks"
                    }
                    WPFUnknownCategory   = [pscustomobject]@{
                        category = "Some Unmapped Category"
                        registry = @([pscustomobject]@{ Path = "HKCU:\Fake5"; Name = "Enabled"; Value = "1"; OriginalValue = "0"; DefaultState = "true" })
                    }
                }
            }
        })

        Mock Get-PSDrive { [pscustomobject]@{ Name = "HKU" } } -ParameterFilter { $Name -eq "HKU" }
        Mock New-PSDrive { }
        Mock Test-Path { $false }
        Mock Get-ItemProperty { $null }
        Mock Write-WinUtilLog { }
    }

    It "groups applied/not-applied tweaks and toggles by category" {
        $result = Get-WinUtilTweaksStateReport

        $result.collectionStatus | Should -Be "collected"
        $result.essentialTweaks.WPFTweaksApplied | Should -BeTrue
        $result.essentialTweaks.WPFTweaksNotApplied | Should -BeFalse
        $result.customizePreferences.WPFToggleCustomize | Should -BeTrue
        $result.advancedTweaks.WPFTweaksAdvanced | Should -BeFalse
        @($result.performancePlans.PSObject.Properties).Count | Should -Be 0
    }

    It "reads live toggle state instead of the cached UI state" {
        $script:sync.ToggleStatusCache = @{ WPFToggleCustomize = $true }
        Mock Test-Path { $Path -eq "HKCU:\Fake3" }
        Mock Get-ItemProperty { [pscustomobject]@{ Enabled = "0" } } -ParameterFilter {
            $Path -eq "HKCU:\Fake3"
        }

        $result = Get-WinUtilTweaksStateReport

        $result.customizePreferences.WPFToggleCustomize | Should -BeFalse
        $script:sync.ToggleStatusCache.WPFToggleCustomize | Should -BeTrue
        Should -Invoke -CommandName Get-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKCU:\Fake3"
        }
    }

    It "reports collection as unavailable when a live registry read fails" {
        Mock Test-Path { $Path -eq "HKCU:\Fake3" }
        Mock Get-ItemProperty { Write-Error -Message "Registry access denied" -ErrorAction Stop } -ParameterFilter {
            $Path -eq "HKCU:\Fake3"
        }

        $result = Get-WinUtilTweaksStateReport

        $result.collectionStatus | Should -Be "unavailable"
        @($result.customizePreferences.PSObject.Properties).Count | Should -Be 0
    }

    It "reports collection as unavailable when a configured service cannot be read" {
        $script:sync.configs.tweaks | Add-Member -MemberType NoteProperty -Name WPFTweaksMissingService -Value ([pscustomobject]@{
            category = "Essential Tweaks"
            service = @([pscustomobject]@{ Name = "MissingService"; StartupType = "Disabled" })
        })
        Mock Get-Service { throw "Service access failed" } -ParameterFilter { $Name -eq "MissingService" }

        $result = Get-WinUtilTweaksStateReport

        $result.collectionStatus | Should -Be "unavailable"
        @($result.essentialTweaks.PSObject.Properties).Count | Should -Be 0
    }

    It "marks only the affected tweak false when a configured service is absent" {
        $script:sync.configs.tweaks | Add-Member -MemberType NoteProperty -Name WPFTweaksMissingService -Value ([pscustomobject]@{
            category = "Essential Tweaks"
            service = @([pscustomobject]@{ Name = "MissingService"; StartupType = "Disabled" })
        })
        Mock Get-Service {
            Write-Error -Message "Cannot find any service with service name 'MissingService'." `
                -Category ObjectNotFound -ErrorId NoServiceFoundForGivenName -ErrorAction Stop
        } -ParameterFilter { $Name -eq "MissingService" }

        $result = Get-WinUtilTweaksStateReport

        $result.collectionStatus | Should -Be "collected"
        $result.essentialTweaks.WPFTweaksApplied | Should -BeTrue
        $result.essentialTweaks.WPFTweaksMissingService | Should -BeFalse
    }

    It "lists combobox and script-only tweaks as not evaluable instead of silently dropping them" {
        $result = Get-WinUtilTweaksStateReport

        $result.notEvaluable | Should -Contain "WPFComboExample"
        $result.notEvaluable | Should -Contain "WPFScriptOnly"
    }

    It "excludes action buttons and unmapped categories entirely" {
        $result = Get-WinUtilTweaksStateReport

        $result.advancedTweaks.PSObject.Properties.Name | Should -Not -Contain "WPFButtonExample"
        $result.notEvaluable | Should -Not -Contain "WPFButtonExample"
        $result.notEvaluable | Should -Not -Contain "WPFUnknownCategory"
        ($result.essentialTweaks.PSObject.Properties.Name +
         $result.customizePreferences.PSObject.Properties.Name +
         $result.advancedTweaks.PSObject.Properties.Name +
         $result.performancePlans.PSObject.Properties.Name) | Should -Not -Contain "WPFUnknownCategory"
    }

    It "returns empty groups instead of throwing when Invoke-WinUtilCurrentSystem fails" {
        Mock Invoke-WinUtilCurrentSystem { throw "Registry access denied" }

        # Calling this directly (rather than via a wrapped scriptblock piped to Should -Not -Throw)
        # avoids a PowerShell scoping pitfall where an assignment inside such a scriptblock doesn't
        # reliably propagate to this scope - an uncaught exception here still fails the test anyway.
        $result = Get-WinUtilTweaksStateReport

        # Empty groups alone would be indistinguishable from a successful scan that found nothing
        # notable, so collectionStatus is what actually records that this run failed.
        $result.collectionStatus | Should -Be "unavailable"
        $result.essentialTweaks.PSObject.Properties.Name | Should -Not -Contain "WPFTweaksApplied"
        @($result.essentialTweaks.PSObject.Properties).Count | Should -Be 0
        @($result.customizePreferences.PSObject.Properties).Count | Should -Be 0
        @($result.advancedTweaks.PSObject.Properties).Count | Should -Be 0
        @($result.performancePlans.PSObject.Properties).Count | Should -Be 0
        $result.notEvaluable | Should -BeNullOrEmpty
    }
}
