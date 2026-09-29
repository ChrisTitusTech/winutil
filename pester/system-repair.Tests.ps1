#===========================================================================
# Tests - System repair exit codes
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFSystemRepair.ps1")

    function Step-WinUtilJob { param([string]$Status, [int]$Percent, [string]$State, [string]$Overlay, [switch]$Hide) }
    function Write-WinUtilLog { param($Message, $Level, $Component) }
}

Describe "Invoke-WPFSystemRepair chkdsk exit codes" {
    BeforeEach {
        Mock Write-WinUtilLog { }
        Mock Write-Warning { }
        Mock Step-WinUtilJob { }
    }

    It "treats chkdsk exit code 0 as a clean disk" {
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }

        { Invoke-WPFSystemRepair } | Should -Not -Throw
        Should -Invoke -CommandName Start-Process -Times 3 -Exactly
    }

    It "treats chkdsk exit code 1 as success and says what it means" {
        Mock Start-Process {
            [pscustomobject]@{ ExitCode = $(if (($ArgumentList -join " ") -match "chkdsk") { 1 } else { 0 }) }
        }

        { Invoke-WPFSystemRepair } | Should -Not -Throw
        Should -Invoke -CommandName Write-Warning -ParameterFilter {
            $Message -like "*errors were found and fixed*"
        }
    }

    It "treats chkdsk exit code 2 as success and says what it means" {
        Mock Start-Process {
            [pscustomobject]@{ ExitCode = $(if (($ArgumentList -join " ") -match "chkdsk") { 2 } else { 0 }) }
        }

        { Invoke-WPFSystemRepair } | Should -Not -Throw
        Should -Invoke -CommandName Write-Warning -ParameterFilter {
            $Message -like "*cleanup was performed*"
        }
    }

    It "fails on chkdsk exit code 3, which an online scan cannot repair" {
        Mock Start-Process {
            [pscustomobject]@{ ExitCode = $(if (($ArgumentList -join " ") -match "chkdsk") { 3 } else { 0 }) }
        }

        { Invoke-WPFSystemRepair } | Should -Throw "*Checking the disk for errors failed with exit code 3*"
    }

    It "does not run the later steps once chkdsk has failed" {
        Mock Start-Process {
            [pscustomobject]@{ ExitCode = $(if (($ArgumentList -join " ") -match "chkdsk") { 3 } else { 0 }) }
        }

        { Invoke-WPFSystemRepair } | Should -Throw
        Should -Invoke -CommandName Start-Process -Times 1 -Exactly
    }
}

Describe "Invoke-WPFSystemRepair per step codes" {
    BeforeEach {
        Mock Write-WinUtilLog { }
        Mock Write-Warning { }
        Mock Step-WinUtilJob { }
    }

    It "accepts 3010 from DISM as a repaired image awaiting a restart" {
        Mock Start-Process {
            [pscustomobject]@{ ExitCode = $(if (($ArgumentList -join " ") -match "dism") { 3010 } else { 0 }) }
        }

        { Invoke-WPFSystemRepair } | Should -Not -Throw
        Should -Invoke -CommandName Write-Warning -ParameterFilter {
            $Message -like "*a restart is needed*"
        }
    }

    It "fails on 3010 from chkdsk, where it does not mean a pending restart" {
        Mock Start-Process {
            [pscustomobject]@{ ExitCode = $(if (($ArgumentList -join " ") -match "chkdsk") { 3010 } else { 0 }) }
        }

        { Invoke-WPFSystemRepair } | Should -Throw "*exit code 3010*"
    }

    It "fails on any non-zero from sfc, which has no success codes of its own" {
        Mock Start-Process {
            [pscustomobject]@{ ExitCode = $(if (($ArgumentList -join " ") -match "sfc") { 1 } else { 0 }) }
        }

        { Invoke-WPFSystemRepair } | Should -Throw "*Scanning protected system files failed with exit code 1*"
    }
}
