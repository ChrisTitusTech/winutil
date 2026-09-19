#===========================================================================
# Tests - Package run outcomes
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    . (Join-Path $script:repoRoot "functions\private\Install-WinUtilProgramWinget.ps1")
    . (Join-Path $script:repoRoot "functions\private\Install-WinUtilProgramChoco.ps1")
    . (Join-Path $script:repoRoot "functions\private\Complete-WinUtilPackageRun.ps1")

    function Step-WinUtilJob { param([string]$Status, [int]$Percent, [string]$State, [string]$Overlay, [switch]$Hide) }
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

    It "skips a per-user package that elevated WinGet cannot update during install" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = -1978335107 } }

        $result = Install-WinUtilProgramWinget -Action Install -Programs @("Microsoft.Sysinternals.ProcessExplorer")

        $result.Outcome | Should -Be "Skipped"
        $result.Detail | Should -Be "already installed for the current user; elevated WinUtil cannot update it"
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "INFO" -and $Message -like "*skipped: Microsoft.Sysinternals.ProcessExplorer*"
        }
        Should -Invoke -CommandName Start-Process -Times 1 -Exactly
    }

    It "skips actions that elevated WinGet cannot perform on a per-user package" {
        $expectedDetails = @{
            Upgrade = "not upgraded; installed for the current user and elevated WinUtil cannot modify it"
            Uninstall = "remains installed for the current user; elevated WinUtil cannot uninstall it"
        }

        foreach ($action in $expectedDetails.Keys) {
            Mock Start-Process { [pscustomobject]@{ ExitCode = -1978335107 } }

            $result = Install-WinUtilProgramWinget -Action $action -Programs @("Microsoft.Sysinternals.ProcessExplorer")

            $result.Outcome | Should -Be "Skipped"
            $result.Detail | Should -Be $expectedDetails[$action]
            $result.ExitCode | Should -Be -1978335107
        }

        Should -Invoke -CommandName Start-Process -Times 2 -Exactly
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
        Mock Get-Command { "choco" } -ParameterFilter { $Name -eq "choco" }
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

    It "fails instead of reusing a stale exit code when Chocolatey is unavailable" {
        $global:LASTEXITCODE = 0
        Mock Get-Command { $null } -ParameterFilter { $Name -eq "choco" }

        $result = Install-WinUtilProgramChoco -Action Uninstall -Programs @("git")

        $result.Outcome | Should -Be "Failed"
        $result.ExitCode | Should -Be -1
        $result.Detail | Should -Be "Chocolatey command did not start"
    }
}

Describe "Complete-WinUtilPackageRun" {
    BeforeEach {
        Mock Write-WinUtilLog { }
        Mock Write-Host { }
        Mock Write-Warning { }
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

    It "does not fail an install when every selected package is already present" {
        $results = @(
            [pscustomobject]@{ Package = "Microsoft.Sysinternals.ProcessMonitor"; Outcome = "Skipped"; Detail = "no applicable update" },
            [pscustomobject]@{ Package = "Microsoft.Sysinternals.ProcessExplorer"; Action = "Install"; ExitCode = -1978335107; Outcome = "Skipped"; Detail = "already installed for the current user; elevated WinUtil cannot update it" }
        )

        { Complete-WinUtilPackageRun -Action "Install" -Results $results } | Should -Not -Throw
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Message -eq "Install summary: 0 succeeded, 2 skipped, 0 failed"
        }
        Should -Invoke -CommandName Write-Warning -Times 1 -Exactly -ParameterFilter {
            $Message -eq "1 package action(s) were skipped because elevated WinUtil cannot modify user-scoped installations."
        }
    }

    It "does not fail the reported two-package uninstall when elevated WinGet cannot act on user scope" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = -1978335107 } }
        $results = @(Install-WinUtilProgramWinget -Action Uninstall -Programs @(
            "Microsoft.Sysinternals.ProcessMonitor",
            "Microsoft.Sysinternals.ProcessExplorer"
        ))

        { Complete-WinUtilPackageRun -Action "Uninstall" -Results $results } | Should -Not -Throw
        @($results | Where-Object Outcome -eq "Skipped").Count | Should -Be 2
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Message -eq "Uninstall summary: 0 succeeded, 2 skipped, 0 failed"
        }
        Should -Invoke -CommandName Write-Warning -Times 1 -Exactly -ParameterFilter {
            $Message -eq "2 package action(s) were skipped because elevated WinUtil cannot modify user-scoped installations."
        }
    }

    It "fails the job when a package failed" {
        $results = @(
            [pscustomobject]@{ Package = "a"; Outcome = "Succeeded"; Detail = "exit code 0" },
            [pscustomobject]@{ Package = "b"; Outcome = "Failed"; Detail = "exit code 5" }
        )

        $caught = $null
        try {
            Complete-WinUtilPackageRun -Action "Install" -Results $results
        } catch {
            $caught = $_
        }

        $caught.Exception.Message | Should -BeLike "1 of 2 package(s) failed: b. *"
        $caught.Exception.Data["WinUtilErrorReported"] | Should -BeTrue
    }

    It "accepts an empty run" {
        { Complete-WinUtilPackageRun -Action "Install" -Results @() } | Should -Not -Throw
    }
}
