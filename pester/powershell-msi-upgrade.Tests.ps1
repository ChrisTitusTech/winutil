Describe "PowerShell MSI upgrade" {
    BeforeAll {
        . "$PSScriptRoot/../functions/private/Install-WinUtilProgramWinget.ps1"
        . "$PSScriptRoot/../functions/private/Write-WinUtilLog.ps1"
    }

    BeforeEach {
        Mock Test-WinUtilPowerShellMSIUpgradeAllowed { $true }
        Mock Write-WinUtilLog {}
        Mock Test-Path { $true }
        Mock Remove-Item {}

        Mock Get-ItemProperty {
            [pscustomobject]@{
                WindowsInstaller = 1
                DisplayName = "PowerShell 7-x64"
                InstallLocation = "C:\Program Files\PowerShell\7"
                DisplayVersion = "7.5.2"
            }
        }

        Mock Get-WinUtilPowerShellVersion { "7.5.2" }
        Mock Get-WinUtilPowerShellArchitecture { "X64" }
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }

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

    It "treats reboot exit code <Code> as successful" -TestCases @(@{ Code = 3010 }, @{ Code = 1641 }) {
        param($Code)
        Mock Start-Process { [pscustomobject]@{ ExitCode = $Code } }
        $result = Update-WinUtilPowerShellMSI
        $result.Outcome | Should -Be "Succeeded"
        $result.ExitCode | Should -Be $Code
        Should -Invoke Start-Process -Times 1 -Exactly
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

    It "reports MSI handling and still upgrades other packages with WinGet all" {
        $result = @(Install-WinUtilProgramWinget -Action Upgrade -Programs @("all"))
        $result.Count | Should -Be 2
        $result[0].Manager | Should -Be "msi"
        $result[0].Outcome | Should -Be "Succeeded"
        $result[1].Manager | Should -Be "winget"
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq "winget" -and $ArgumentList -contains "--all"
        }
    }

    It "reports MSI failures even when the remaining upgrades succeed" {
        Mock Update-WinUtilPowerShellMSI { [pscustomobject]@{ Outcome = 'Failed'; ExitCode = -1; Detail = 'failed' } }
        $result = @(Install-WinUtilProgramWinget -Action Upgrade -Programs @('all'))
        $result[0].Outcome | Should -Be 'Failed'
        $result[1].Outcome | Should -Be 'Succeeded'
    }

    It "resolves the official MSI registration by ProductCode without uninstall InstallLocation" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ WindowsInstaller = 1; DisplayName = 'PowerShell 7-x64'; PSChildName = '{stable-product}' }
        } -ParameterFilter { $Path[0] -like '*Uninstall*' }
        Mock Get-ItemProperty {
            @(
                [pscustomobject]@{ ProductCode = '{other-product}'; InstallLocation = 'C:\Wrong' },
                [pscustomobject]@{ ProductCode = '{stable-product}'; InstallLocation = 'C:\Custom\PowerShell\7' }
            )
        } -ParameterFilter { $Path[0] -like '*InstalledVersions*' }
        (Update-WinUtilPowerShellMSI).Outcome | Should -Be 'Succeeded'
        Should -Invoke Get-WinUtilPowerShellVersion -Times 1 -Exactly -ParameterFilter { $Path -eq 'C:\Custom\PowerShell\7\pwsh.exe' }
    }

    It "does not download an MSI when pins exist or cannot be checked" {
        Mock Test-WinUtilPowerShellMSIUpgradeAllowed { $false }
        (Update-WinUtilPowerShellMSI).Outcome | Should -Be 'Skipped'
        Should -Invoke Invoke-RestMethod -Times 0 -Exactly
        Should -Invoke Start-Process -Times 0 -Exactly
    }

    It "matches official versioned MSI names" {
        Mock Get-ItemProperty { [pscustomobject]@{ WindowsInstaller = 1; DisplayName = 'PowerShell 7.5.2.0-x64'; InstallLocation = 'C:\PowerShell\7' } }
        (Update-WinUtilPowerShellMSI).Outcome | Should -Be 'Succeeded'
    }

    It "uses the installed x86 architecture on a different host architecture" {
        Mock Get-WinUtilPowerShellArchitecture { 'X86' }
        Mock Invoke-RestMethod { [pscustomobject]@{ tag_name = 'v7.5.3'; assets = @(
            [pscustomobject]@{ name = 'PowerShell-7.5.3-win-x86.msi'; browser_download_url = 'https://example.com/x86.msi' },
            [pscustomobject]@{ name = 'PowerShell-7.5.3-win-x64.msi'; browser_download_url = 'https://example.com/x64.msi' }
        ) } }
        (Update-WinUtilPowerShellMSI).Outcome | Should -Be 'Succeeded'
        Should -Invoke Invoke-WebRequest -Times 1 -Exactly -ParameterFilter { $Uri -eq 'https://example.com/x86.msi' }
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
                    DisplayName = "PowerShell 7-x64"
                    InstallLocation = "C:\PowerShell\7"
                    DisplayVersion = "7.5.2"
                }
            )
        }

        $result = Update-WinUtilPowerShellMSI

        $result.Outcome | Should -Not -Be "NotInstalled"
    }
}

Describe "MSI pin protection" {
    BeforeAll {
        . "$PSScriptRoot/../functions/private/Install-WinUtilProgramWinget.ps1"
        function winget { }
    }
    It "allows MSI only when pin listing succeeds without a table" {
        Mock winget { $global:LASTEXITCODE = 0; 'No pins exist.' }
        Test-WinUtilPowerShellMSIUpgradeAllowed | Should -BeTrue
    }
    It "blocks MSI for a localized pin table" {
        Mock winget { $global:LASTEXITCODE = 0; "Nom ID Version`n-------------------`nPowerShell Microsoft.PowerShell 7.5" }
        Test-WinUtilPowerShellMSIUpgradeAllowed | Should -BeFalse
    }
    It "blocks MSI when the pin command fails" {
        Mock winget { $global:LASTEXITCODE = 1; 'error' }
        Test-WinUtilPowerShellMSIUpgradeAllowed | Should -BeFalse
    }
    It "blocks MSI when the pin command produces no output" {
        Mock winget { $global:LASTEXITCODE = 0 }
        Test-WinUtilPowerShellMSIUpgradeAllowed | Should -BeFalse
    }
}
