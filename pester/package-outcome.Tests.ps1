#===========================================================================
# Tests - Package run outcomes
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilWinGetErrorMessage.ps1")
    . (Join-Path $script:repoRoot "functions\private\Install-WinUtilProgramWinget.ps1")
    . (Join-Path $script:repoRoot "functions\private\Install-WinUtilProgramChoco.ps1")
    . (Join-Path $script:repoRoot "functions\private\Complete-WinUtilPackageRun.ps1")

    function Step-WinUtilJob { param([string]$Status, [int]$Percent, [string]$State, [string]$Overlay, [switch]$Hide) }
    function Write-WinUtilLog {
        param($Message, $Level, $Component)
    }
    function Invoke-WinUtilUnelevated {
        param([string]$FilePath, [string[]]$ArgumentList, [int]$TimeoutSeconds)
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

    It "retries as the signed in user when WinGet refuses a user scope package" {
        # WinGet answers APPINSTALLER_CLI_ERROR_ADMIN_CONTEXT_ACTION_PROHIBITED for anything
        # installed in user scope while elevated, and WinUtil is always elevated
        Mock Start-Process { [pscustomobject]@{ ExitCode = -1978335107 } }
        Mock Invoke-WinUtilUnelevated { [pscustomobject]@{ ExitCode = 0; Output = ""; TimedOut = $false } }

        $result = Install-WinUtilProgramWinget -Action Uninstall -Programs @("MullvadVPN.MullvadBrowser")

        $result.Outcome | Should -Be "Succeeded"
        Should -Invoke -CommandName Invoke-WinUtilUnelevated -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq "winget" -and ($ArgumentList -join " ") -like "*uninstall*MullvadVPN.MullvadBrowser*"
        }
    }

    It "reports the failure when the retry as the signed in user also fails" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = -1978335107 } }
        Mock Invoke-WinUtilUnelevated { [pscustomobject]@{ ExitCode = -1978335212; Output = ""; TimedOut = $false } }

        $result = Install-WinUtilProgramWinget -Action Uninstall -Programs @("MullvadVPN.MullvadBrowser")

        $result.Outcome | Should -Be "Failed"
    }

    It "does not go looking for the signed in user when the command simply worked" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }
        Mock Invoke-WinUtilUnelevated { [pscustomobject]@{ ExitCode = 0; Output = ""; TimedOut = $false } }

        $result = Install-WinUtilProgramWinget -Action Uninstall -Programs @("Some.Package")

        $result.Outcome | Should -Be "Succeeded"
        Should -Invoke -CommandName Invoke-WinUtilUnelevated -Times 0 -Exactly
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

Describe "Install-WinUtilProgramChoco outcomes" {
    BeforeAll {
        function choco { $global:LASTEXITCODE = 0 }
    }

    BeforeEach {
        Mock Write-WinUtilLog { }
        Mock Step-WinUtilJob { }
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
