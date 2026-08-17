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

    It "treats a reboot requirement as success, not failure" {
        # 3010 and 1641 mean the installer worked and Windows wants a restart. Counting them as
        # failures marks a whole upgrade run broken when nothing went wrong.
        foreach ($code in @(3010, 1641)) {
            Mock Start-Process { [pscustomobject]@{ ExitCode = $code } }.GetNewClosure()

            $result = Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git")

            $result.Outcome | Should -Be "Succeeded" -Because "exit code $code means the install worked"
            $result.Detail | Should -Match "restart"
        }
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
    }

    It "prefers the module over the command line" {
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult }

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

    It "treats an Ok status with a reboot exit code as success" {
        # Seen upgrading VCRedist on a real machine: status Ok, installer code 3010. Requiring a
        # zero exit code there reported a working upgrade as a failed one.
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult -Status "Ok" -InstallerErrorCode 3010 -RebootRequired $true }

        $result = Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git")

        $result.Outcome | Should -Be "Succeeded"
        $result.Detail | Should -Match "restart"
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
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult }

        Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git") -Label "Git.Git (2/7)" | Out-Null

        Should -Invoke -CommandName Invoke-WinUtilWinGetCommand -Times 1 -Exactly -ParameterFilter {
            $Label -eq "Git.Git (2/7)"
        }
    }

    It "uses the uninstall cmdlet for an uninstall" {
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult } -ParameterFilter { $Command -eq "Uninstall-WinGetPackage" }

        Install-WinUtilProgramWinget -Action Uninstall -Programs @("Git.Git") | Out-Null

        Should -Invoke -CommandName Invoke-WinUtilWinGetCommand -Times 1 -Exactly -ParameterFilter {
            $Command -eq "Uninstall-WinGetPackage"
        }
    }

    It "reports the extended error code when a package fails" {
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

    # The action picks the cmdlet, so an upgrade run upgrades rather than re-running installers
    It "uses the upgrade cmdlet for an upgrade" {
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult -Status "NoApplicableUpgrade" } -ParameterFilter { $Command -eq "Update-WinGetPackage" }

        $result = Install-WinUtilProgramWinget -Action Upgrade -Programs @("Git.Git")

        $result.Outcome | Should -Be "Skipped"
        Should -Invoke -CommandName Invoke-WinUtilWinGetCommand -Times 1 -Exactly -ParameterFilter {
            $Command -eq "Update-WinGetPackage"
        }
        Should -Invoke -CommandName Invoke-WinUtilWinGetCommand -Times 0 -Exactly -ParameterFilter {
            $Command -eq "Install-WinGetPackage"
        }
    }

    It "installs a package that is not present" {
        Mock Invoke-WinUtilWinGetCommand { New-WinGetResult }

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
    BeforeAll {
        function choco { $global:LASTEXITCODE = 0 }
    }

    BeforeEach {
        Mock Write-WinUtilLog { }
        Mock Write-WinUtilJobProgress { }
    }

    It "treats a reboot-required exit code as success" {
        Mock choco { $global:LASTEXITCODE = 3010 }

        $result = Install-WinUtilProgramChoco -Action Install -Programs @("git")
        $result.Outcome | Should -Be "Succeeded"
        $result.Detail | Should -Match "restart"
    }

    It "reports a non-zero exit code as a failure" {
        Mock choco { $global:LASTEXITCODE = 1 }

        (Install-WinUtilProgramChoco -Action Install -Programs @("git")).Outcome | Should -Be "Failed"
    }

    It "reports nothing-to-do as skipped rather than failed" {
        Mock choco { $global:LASTEXITCODE = 2 }

        (Install-WinUtilProgramChoco -Action Install -Programs @("git")).Outcome | Should -Be "Skipped"
    }

    # The reason is in choco's own output, which is logged; the result carries the code
    It "reports the exit code when choco fails" {
        Mock choco { $global:LASTEXITCODE = 1; "git is not installed. Cannot uninstall a non-existent package." }

        $result = Install-WinUtilProgramChoco -Action Uninstall -Programs @("git")

        $result.Outcome | Should -Be "Failed"
        $result.Detail | Should -Be "exit code 1"
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
