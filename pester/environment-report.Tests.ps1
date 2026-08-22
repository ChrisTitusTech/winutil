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
}

Describe "Get-WinUtilEnvironmentReport" {
    BeforeEach {
        # Keep this Describe focused on the top-level schema; tweaksState grouping/detection has
        # its own dedicated Describe below with its own registry fixture.
        Mock Get-WinUtilTweaksStateReport {
            [pscustomobject]@{
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
        $report = Get-WinUtilEnvironmentReport | ConvertTo-Json -Depth 6

        $report | Should -Not -Match 'ComputerName|UserName|UserProfile|IPAddress|MacAddress|SerialNumber|ProductKey|Environment'
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

    It "flags a pending reboot from PendingFileRenameOperations" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ PendingFileRenameOperations = @("a", "b") }
        } -ParameterFilter { $Name -eq "PendingFileRenameOperations" }

        $report = Get-WinUtilEnvironmentReport

        $report.system.pendingRebootRequired | Should -BeTrue
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

        $result.essentialTweaks.WPFTweaksApplied | Should -BeTrue
        $result.essentialTweaks.WPFTweaksNotApplied | Should -BeFalse
        $result.customizePreferences.WPFToggleCustomize | Should -BeTrue
        $result.advancedTweaks.WPFTweaksAdvanced | Should -BeFalse
        @($result.performancePlans.PSObject.Properties).Count | Should -Be 0
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

        $result.essentialTweaks.PSObject.Properties.Name | Should -Not -Contain "WPFTweaksApplied"
        @($result.essentialTweaks.PSObject.Properties).Count | Should -Be 0
        @($result.customizePreferences.PSObject.Properties).Count | Should -Be 0
        @($result.advancedTweaks.PSObject.Properties).Count | Should -Be 0
        @($result.performancePlans.PSObject.Properties).Count | Should -Be 0
        $result.notEvaluable | Should -BeNullOrEmpty
    }
}
