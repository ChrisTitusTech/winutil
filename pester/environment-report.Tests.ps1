#===========================================================================
# Tests - Environment Report
#===========================================================================

BeforeAll {
    . (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")) "functions\private\Get-WinUtilEnvironmentReport.ps1")
}

Describe "Get-WinUtilEnvironmentReport" {
    BeforeEach {
        Mock Get-Command { $null } -ParameterFilter { $CommandType -eq "Application" }
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
        Mock Get-WindowsOptionalFeature {
            return [pscustomobject]@{ State = "Enabled" }
        }
    }

    It "returns the versioned allowlisted report schema" {
        $report = Get-WinUtilEnvironmentReport

        $report.schemaVersion | Should -Be "1.0"
        $report.generatedAtUtc | Should -Match '^\d{4}-\d{2}-\d{2}T'
        $report.windows.edition | Should -Be "Windows 11 Pro"
        $report.hardware.cpuModel | Should -Be "Example CPU"
        $report.hardware.logicalProcessorCount | Should -Be 8
        $report.hardware.totalMemoryGB | Should -Be 16
        $report.powershell.PSObject.Properties.Name | Should -Be @("edition", "version")
        $report.developerTools.PSObject.Properties.Name | Should -Be @("git", "java", "nodejs", "python", "docker")
        $report.windowsFeatures.PSObject.Properties.Name | Should -Be @("hyperV", "wsl", "windowsSandbox")
        $report.windowsFeatures.hyperV.enabled | Should -BeTrue
    }

    It "contains no fields outside the approved report schema" {
        $report = Get-WinUtilEnvironmentReport | ConvertTo-Json -Depth 6

        $report | Should -Not -Match 'ComputerName|UserName|UserProfile|IPAddress|MacAddress|SerialNumber|ProductKey|Environment'
    }

    It "keeps missing developer tools and unavailable features non-terminating" {
        Mock Get-WindowsOptionalFeature { throw "Feature unavailable" }

        $report = Get-WinUtilEnvironmentReport

        $report.developerTools.git.installed | Should -BeFalse
        $report.developerTools.git.version | Should -BeNullOrEmpty
        $report.windowsFeatures.hyperV.enabled | Should -BeFalse
        $report.windowsFeatures.wsl.enabled | Should -BeFalse
        $report.windowsFeatures.windowsSandbox.enabled | Should -BeFalse
    }
}
