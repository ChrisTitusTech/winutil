#===========================================================================
# Tests - Package run outcomes
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilWinGetErrorMessage.ps1")
    . (Join-Path $script:repoRoot "functions\private\Install-WinUtilProgramWinget.ps1")
    . (Join-Path $script:repoRoot "functions\private\Install-WinUtilProgramChoco.ps1")
    . (Join-Path $script:repoRoot "functions\private\Complete-WinUtilPackageRun.ps1")

    # The CLI path is what these tests cover; the module path is verified against real winget
    function Install-WinUtilWinGetClient { $false }
    function Invoke-WinUtilWinGetCommand { param([string]$Command, [hashtable]$Parameters, [int]$ProgressBase, [int]$ProgressSpan, [string]$Label) }
    function Write-WinUtilJobProgress { param([string]$Status, [int]$Percent, [string]$State, [string]$Overlay, [switch]$Hide) }
    function Write-WinUtilLog {
        param($Message, $Level, $Component)
    }
}

Describe "Install-WinUtilProgramWinget outcomes" {
    BeforeEach {
        Mock Write-WinUtilLog { }
    }

    It "reports success for exit code 0" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }

        $result = Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git")

        $result.Outcome | Should -Be "Succeeded"
        $result.Package | Should -Be "Git.Git"
        $result.Manager | Should -Be "winget"
    }

    It "reports an already installed package as skipped rather than failed" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = -1978335135 } }

        $result = Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git")

        $result.Outcome | Should -Be "Skipped"
        $result.Detail | Should -Be "already installed"
    }

    It "reports any other exit code as a failure" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = -1978335212 } }

        $result = Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git")

        $result.Outcome | Should -Be "Failed"
        $result.ExitCode | Should -Be -1978335212
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and $Message -like "*failed: Git.Git*"
        }
    }

    It "returns one result per package" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }

        $results = @(Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git", "VideoLAN.VLC"))

        $results.Count | Should -Be 2
    }
}

Describe "Install-WinUtilProgramWinget through the WinGet client module" {
    BeforeAll {
        function New-WinGetResult {
            param([string]$Status = "Ok", [int]$InstallerErrorCode = 0, [bool]$RebootRequired = $false)
            [pscustomobject]@{
                Id = "Git.Git"
                Name = "Git"
                Status = $Status
                InstallerErrorCode = $InstallerErrorCode
                RebootRequired = $RebootRequired
            }
        }
    }

    BeforeEach {
        Mock Write-WinUtilLog { }
        Mock Install-WinUtilWinGetClient { $true }
        Mock Start-Process { throw "the command line must not be used when the module is available" }
        # Not installed unless a test says otherwise
        Mock Invoke-WinUtilWinGetCommand { } -ParameterFilter { $Command -eq "Get-WinGetPackage" }
    }

    It "prefers the module over the command line" {
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult } -ParameterFilter { $Command -ne "Get-WinGetPackage" }

        $result = Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git")

        $result.Outcome | Should -Be "Succeeded"
        Should -Invoke -CommandName Invoke-WinUtilWinGetCommand -Times 1 -Exactly -ParameterFilter {
            $Command -eq "Install-WinGetPackage" -and
                $Parameters.Id -eq "Git.Git" -and
                $Parameters.Mode -eq "Silent" -and
                $Label -eq "Git.Git"
        }
        Should -Invoke -CommandName Start-Process -Times 0 -Exactly
    }

    It "passes the progress slice through so the bar moves within a package" {
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult }

        Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git") -ProgressBase 40 -ProgressSpan 20 | Out-Null

        Should -Invoke -CommandName Invoke-WinUtilWinGetCommand -Times 1 -Exactly -ParameterFilter {
            $ProgressBase -eq 40 -and $ProgressSpan -eq 20
        }
    }

    # Without it the status reads as a package on its own, losing where the run is overall
    It "keeps the caller's label so the position in the run stays visible" {
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult } -ParameterFilter { $Command -ne "Get-WinGetPackage" }

        Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git") -Label "Git.Git (2/7)" | Out-Null

        Should -Invoke -CommandName Invoke-WinUtilWinGetCommand -Times 1 -Exactly -ParameterFilter {
            $Command -ne "Get-WinGetPackage" -and $Label -eq "Git.Git (2/7)"
        }
    }

    It "uses the uninstall cmdlet for an uninstall" {
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult } -ParameterFilter { $Command -eq "Get-WinGetPackage" }
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult } -ParameterFilter { $Command -eq "Uninstall-WinGetPackage" }

        Install-WinUtilProgramWinget -Action Uninstall -Programs @("Git.Git") | Out-Null

        Should -Invoke -CommandName Invoke-WinUtilWinGetCommand -Times 1 -Exactly -ParameterFilter {
            $Command -eq "Uninstall-WinGetPackage"
        }
    }

    # Asking winget to remove something it cannot see returns UninstallError, which reads as a
    # failed run for a package the user does not have.
    It "skips uninstalling a package that is not installed" {
        $result = Install-WinUtilProgramWinget -Action Uninstall -Programs @("Git.Git")

        $result.Outcome | Should -Be "Skipped"
        $result.Detail | Should -Be "not installed"
        Should -Invoke -CommandName Invoke-WinUtilWinGetCommand -Times 0 -Exactly -ParameterFilter {
            $Command -eq "Uninstall-WinGetPackage"
        }
    }

    It "reports the extended error code when a package fails" {
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult } -ParameterFilter { $Command -eq "Get-WinGetPackage" }
        Mock Invoke-WinUtilWinGetCommand {
            [pscustomobject]@{
                Status = "UninstallError"
                InstallerErrorCode = 0
                ExtendedErrorCode = "Exception from HRESULT: 0x8A15004F"
                RebootRequired = $false
            }
        } -ParameterFilter { $Command -eq "Uninstall-WinGetPackage" }

        $result = Install-WinUtilProgramWinget -Action Uninstall -Programs @("Git.Git")

        $result.Outcome | Should -Be "Failed"
        $result.Detail | Should -Match "0x8A15004F"
    }

    # Install-WinGetPackage re-downloads and re-runs the installer for a package that is
    # already present, so an install pass would reinstall the whole machine.
    It "upgrades a package that is already installed instead of reinstalling it" {
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult } -ParameterFilter { $Command -eq "Get-WinGetPackage" }
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult -Status "NoApplicableUpgrade" } -ParameterFilter { $Command -eq "Update-WinGetPackage" }

        $result = Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git")

        $result.Outcome | Should -Be "Skipped"
        Should -Invoke -CommandName Invoke-WinUtilWinGetCommand -Times 1 -Exactly -ParameterFilter {
            $Command -eq "Update-WinGetPackage"
        }
        Should -Invoke -CommandName Invoke-WinUtilWinGetCommand -Times 0 -Exactly -ParameterFilter {
            $Command -eq "Install-WinGetPackage"
        }
    }

    It "installs a package that is not present" {
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult } -ParameterFilter { $Command -ne "Get-WinGetPackage" }

        Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git") | Out-Null

        Should -Invoke -CommandName Invoke-WinUtilWinGetCommand -Times 1 -Exactly -ParameterFilter {
            $Command -eq "Install-WinGetPackage"
        }
    }

    It "treats a nothing-to-do status as skipped" {
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult -Status "NoApplicableUpgrade" }

        (Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git")).Outcome | Should -Be "Skipped"
    }

    It "treats an installer error as a failure" {
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult -Status "InstallError" -InstallerErrorCode 1603 }

        $result = Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git")

        $result.Outcome | Should -Be "Failed"
        $result.ExitCode | Should -Be 1603
    }

    It "treats no result at all as a failure" {
        Mock Invoke-WinUtilWinGetCommand { }

        (Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git")).Outcome | Should -Be "Failed"
    }

    It "notes when a package wants a reboot" {
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult -RebootRequired $true }

        Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git") | Out-Null

        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "WARN" -and $Message -like "*needs a reboot*"
        }
    }
}

Describe "Install-WinUtilProgramChoco outcomes" {
    BeforeEach {
        Mock Write-WinUtilLog { }
    }

    It "treats a reboot-required exit code as success" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = 3010 } }

        (Install-WinUtilProgramChoco -Action Install -Programs @("git")).Outcome | Should -Be "Succeeded"
    }

    It "reports a non-zero exit code as a failure" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = 1 } }

        (Install-WinUtilProgramChoco -Action Install -Programs @("git")).Outcome | Should -Be "Failed"
    }
}

Describe "Complete-WinUtilPackageRun" {
    BeforeEach {
        Mock Write-WinUtilLog { }
        Mock Write-Host { }
    }

    It "reports the counts of each outcome" {
        $results = @(
            [pscustomobject]@{ Package = "a"; Outcome = "Succeeded"; Detail = "exit code 0" },
            [pscustomobject]@{ Package = "b"; Outcome = "Skipped"; Detail = "already installed" }
        )

        Complete-WinUtilPackageRun -Action "Install" -Results $results

        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Message -eq "Install summary: 1 succeeded, 1 skipped, 0 failed"
        }
    }

    It "fails the job when a package failed" {
        $results = @(
            [pscustomobject]@{ Package = "a"; Outcome = "Succeeded"; Detail = "exit code 0" },
            [pscustomobject]@{ Package = "b"; Outcome = "Failed"; Detail = "exit code 5" }
        )

        { Complete-WinUtilPackageRun -Action "Install" -Results $results } |
            Should -Throw "1 of 2 package(s) failed: b. *"
    }

    It "accepts an empty run" {
        { Complete-WinUtilPackageRun -Action "Install" -Results @() } | Should -Not -Throw
    }
}
