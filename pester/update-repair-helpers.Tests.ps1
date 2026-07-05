#===========================================================================
# Tests - Windows Update Repair Helpers
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Test-WinUtilTrustedInstallerPath.ps1")

    function Write-WinUtilLog {
        param($Message, $Level, $Component)
        $null = $Message
        $null = $Level
        $null = $Component
    }
}

Describe "Test-WinUtilTrustedInstallerPath" {
    BeforeEach {
        $env:SystemRoot = "C:\Windows"
        Mock Write-Warning { }
        Mock Write-WinUtilLog { }
    }

    It "returns true for the expected TrustedInstaller ImagePath" {
        Mock Get-CimInstance {
            [pscustomobject]@{
                Name = "TrustedInstaller"
                PathName = "%SystemRoot%\servicing\TrustedInstaller.exe"
            }
        } -ParameterFilter {
            $ClassName -eq "Win32_Service" -and $Filter -eq "Name='TrustedInstaller'"
        }

        Test-WinUtilTrustedInstallerPath | Should -BeTrue

        Should -Invoke -CommandName Write-Warning -Times 0 -Exactly
    }

    It "warns and returns false when TrustedInstaller points to an encoded PowerShell command" {
        Mock Get-CimInstance {
            [pscustomobject]@{
                Name = "TrustedInstaller"
                PathName = "cmd.exe /c PowerShell.exe -encodedcommand badpayload"
            }
        } -ParameterFilter {
            $ClassName -eq "Win32_Service" -and $Filter -eq "Name='TrustedInstaller'"
        }

        Test-WinUtilTrustedInstallerPath | Should -BeFalse

        Should -Invoke -CommandName Write-Warning -Times 1 -Exactly -ParameterFilter {
            $Message -like "TrustedInstaller service ImagePath looks suspicious:*"
        }
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "WARN" -and $Component -eq "Updates" -and $Message -like "TrustedInstaller service ImagePath looks suspicious:*"
        }
    }

    It "does not block repair when TrustedInstaller cannot be inspected" {
        Mock Get-CimInstance {
            throw "CIM unavailable"
        } -ParameterFilter {
            $ClassName -eq "Win32_Service" -and $Filter -eq "Name='TrustedInstaller'"
        }

        Test-WinUtilTrustedInstallerPath | Should -BeTrue

        Should -Invoke -CommandName Write-Warning -Times 1 -Exactly -ParameterFilter {
            $Message -like "Unable to inspect TrustedInstaller service path:*"
        }
    }
}
