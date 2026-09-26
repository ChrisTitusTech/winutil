Describe "PowerShell MSI upgrade" {
    BeforeAll {
        . "$PSScriptRoot/../functions/private/Install-WinUtilProgramWinget.ps1"

        Mock Write-WinUtilLog {}
        Mock Test-Path { $true }
        Mock Remove-Item {}

        Mock Get-ItemProperty {
            [pscustomobject]@{
                WindowsInstaller = 1
                DisplayName = "PowerShell 7"
                InstallLocation = "C:\Program Files\PowerShell\7"
                DisplayVersion = "7.5.2"
            }
        }

        Mock Get-WinUtilPowerShellVersion { "7.5.2" }

        Mock Invoke-RestMethod {
            [pscustomobject]@{
                tag_name = "v7.5.3"
                assets = @(
                    [pscustomobject]@{
                        name = "PowerShell-7.5.3-win-x64.msi"
                        browser_download_url = "https://example.com/PowerShell.msi"
                        digest = $null
                    }
                )
            }
        }

        Mock Invoke-WebRequest {}
        Mock Get-AuthenticodeSignature {
            [pscustomobject]@{
                Status = "Valid"
                SignerCertificate = [pscustomobject]@{
                    Subject = "CN=Microsoft Corporation"
                }
            }
        }
    }

    It "upgrades MSI PowerShell successfully" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }

        $result = Update-WinUtilPowerShellMSI

        $result.Outcome | Should -Be "Succeeded"
        Should -Invoke Invoke-WebRequest -Times 1
        Should -Invoke Get-AuthenticodeSignature -Times 1
        Should -Invoke Start-Process -Times 1
    }

    It "treats 3010 and 1641 as successful MSI upgrades" {
        foreach ($exitCode in @(3010, 1641)) {
            Mock Start-Process { [pscustomobject]@{ ExitCode = $exitCode } }

            $result = Update-WinUtilPowerShellMSI

            $result.Outcome | Should -Be "Succeeded"
            $result.ExitCode | Should -Be $exitCode

            Should -Invoke Start-Process -Times 1
        }
    }

    It "reports MSI installation failure" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = 1603 } }

        $result = Update-WinUtilPowerShellMSI

        $result.Outcome | Should -Be "Failed"
        Should -Invoke Write-WinUtilLog -ParameterFilter {
            $Level -eq "ERROR"
        }
    }

    It "skips download when PowerShell is already current" {
        Mock Get-WinUtilPowerShellVersion { "7.5.3" }
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }

        $result = Update-WinUtilPowerShellMSI

        $result.Outcome | Should -Be "Skipped"
        Should -Invoke Invoke-WebRequest -Times 0
        Should -Invoke Start-Process -Times 0
    }

    It "returns NotInstalled when PowerShell is not MSI-installed" {
        Mock Get-ItemProperty { $null }

        $result = Update-WinUtilPowerShellMSI

        $result.Outcome | Should -Be "NotInstalled"
        Should -Invoke Invoke-RestMethod -Times 0
        Should -Invoke Start-Process -Times 0
    }

    It "rejects an invalid or missing signer certificate" {
        Mock Get-AuthenticodeSignature {
            [pscustomobject]@{
                Status = "NotTrusted"
                SignerCertificate = $null
            }
        }

        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }

        $result = Update-WinUtilPowerShellMSI

        $result.Outcome | Should -Be "Failed"
        Should -Invoke Start-Process -Times 0
    }

    It "rejects a non-Microsoft certificate containing Microsoft" {
        Mock Get-AuthenticodeSignature {
            [pscustomobject]@{
                Status = "Valid"
                SignerCertificate = [pscustomobject]@{
                    Subject = "CN=Microsoft Malware Research"
                }
            }
        }

        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }

        $result = Update-WinUtilPowerShellMSI

        $result.Outcome | Should -Be "Failed"
        Should -Invoke Start-Process -Times 0
    }

    It "rejects a mismatched SHA256 digest" {
        Mock Invoke-RestMethod {
            [pscustomobject]@{
                tag_name = "v7.5.3"
                assets = @(
                    [pscustomobject]@{
                        name = "PowerShell-7.5.3-win-x64.msi"
                        browser_download_url = "https://example.com/PowerShell.msi"
                        digest = "sha256:0000000000000000000000000000000000000000000000000000000000000000"
                    }
                )
            }
        }

        Mock Get-FileHash {
            [pscustomobject]@{
                Hash = "1111111111111111111111111111111111111111111111111111111111111111"
            }
        }

        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }

        $result = Update-WinUtilPowerShellMSI

        $result.Outcome | Should -Be "Failed"
        Should -Invoke Start-Process -Times 0
    }

    It "uses MSI for selected PowerShell Install and Upgrade" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }

        foreach ($action in @("Install", "Upgrade")) {
            $result = Install-WinUtilProgramWinget `
                -Action $action `
                -Programs @("Microsoft.PowerShell")

            $result.Package | Should -Be "Microsoft.PowerShell"
            $result.Manager | Should -Be "msi"
            $result.Outcome | Should -Be "Succeeded"
        }

        Should -Invoke Start-Process -Times 2
    }

    It "falls back to WinGet when PowerShell is not MSI-installed" {
        Mock Get-ItemProperty { $null }
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }

        $result = Install-WinUtilProgramWinget `
            -Action Upgrade `
            -Programs @("Microsoft.PowerShell")

        $result.Manager | Should -Be "winget"
        $result.Outcome | Should -Be "Succeeded"
        Should -Invoke Start-Process -Times 1
    }

    It "does not fall through to WinGet after MSI handling" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }

        $result = Install-WinUtilProgramWinget `
            -Action Upgrade `
            -Programs @("Microsoft.PowerShell")

        $result.Manager | Should -Be "msi"
        $result.Outcome | Should -Be "Succeeded"

        Should -Invoke Start-Process -Times 1 -ParameterFilter {
            $FilePath -eq "msiexec.exe"
        }
    }

    It "does not use WinGet all when MSI PowerShell is detected" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }

        Install-WinUtilProgramWinget `
            -Action Upgrade `
            -Programs @("all")

        Should -Invoke Start-Process -Times 0 -ParameterFilter {
            $FilePath -eq "winget" -and
            $ArgumentList -contains "--all"
        }
    }

    It "ignores PowerShell preview installations" {
        Mock Get-ItemProperty {
            @(
                [pscustomobject]@{
                    WindowsInstaller = 1
                    DisplayName = "PowerShell 7-preview"
                    InstallLocation = "C:\PowerShell\preview"
                    DisplayVersion = "7.6.0-preview"
                },
                [pscustomobject]@{
                    WindowsInstaller = 1
                    DisplayName = "PowerShell 7"
                    InstallLocation = "C:\PowerShell\7"
                    DisplayVersion = "7.5.2"
                }
            )
        }

        $result = Update-WinUtilPowerShellMSI

        $result.Outcome | Should -Not -Be "NotInstalled"
    }
}
