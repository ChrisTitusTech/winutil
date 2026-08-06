#===========================================================================
# Tests - WinGet result codes
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilWinGetErrorMessage.ps1")
}

Describe "Get-WinUtilWinGetErrorMessage" {
    It "returns nothing for success" {
        Get-WinUtilWinGetErrorMessage -Code 0 | Should -BeNullOrEmpty
    }

    # The command line prints this sentence; the module returns only the HRESULT. Both report
    # the same number, which is what makes one table enough.
    It "explains the user scope uninstall failure that winget words itself" {
        $message = Get-WinUtilWinGetErrorMessage -Code -1978335107

        $message | Should -Match "single user"
        $message | Should -Match "administrator"
        $message | Should -Match "0x8A15007D"
    }

    It "explains the codes that mean there was nothing to do" {
        (Get-WinUtilWinGetErrorMessage -Code -1978335135) | Should -Match "already installed"
        (Get-WinUtilWinGetErrorMessage -Code -1978335189) | Should -Match "no newer version"
    }

    It "explains a missing package and a hash mismatch" {
        (Get-WinUtilWinGetErrorMessage -Code -1978335212) | Should -Match "No package matched"
        (Get-WinUtilWinGetErrorMessage -Code -1978335215) | Should -Match "hash"
    }

    It "still gives the hex code and a reference for anything unknown" {
        $message = Get-WinUtilWinGetErrorMessage -Code -1978335000

        $message | Should -Match "0x8A1500"
        $message | Should -Match "returnCodes"
    }
}

Describe "Package failure reporting" {
    BeforeAll {
        . (Join-Path $script:repoRoot "functions\private\Complete-WinUtilPackageRun.ps1")
        function Write-WinUtilLog { param($Message, $Level, $Component) }
    }

    BeforeEach {
        Mock Write-WinUtilLog { }
        Mock Write-Host { }
    }

    It "repeats a single shared reason so it is not lost" {
        $results = @(
            [pscustomobject]@{ Package = "a"; Outcome = "Failed"; Detail = "UninstallError - user scope" },
            [pscustomobject]@{ Package = "b"; Outcome = "Failed"; Detail = "UninstallError - user scope" }
        )

        { Complete-WinUtilPackageRun -Action "Uninstall" -Results $results } |
            Should -Throw "*a, b. UninstallError - user scope*"
    }

    It "points at the per-package lines when the reasons differ" {
        $results = @(
            [pscustomobject]@{ Package = "a"; Outcome = "Failed"; Detail = "one reason" },
            [pscustomobject]@{ Package = "b"; Outcome = "Failed"; Detail = "another reason" }
        )

        { Complete-WinUtilPackageRun -Action "Uninstall" -Results $results } |
            Should -Throw "*See the lines above for each reason.*"
    }
}
