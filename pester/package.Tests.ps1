#===========================================================================
# Tests - Package Selection and Package Managers
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    if (-not ("PackageManagers" -as [type])) {
        Add-Type @"
public enum PackageManagers
{
    Winget,
    Choco
}
"@
    }

    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilSelectedPackages.ps1")
    . (Join-Path $script:repoRoot "functions\private\Test-WinUtilPackageManager.ps1")
    . (Join-Path $script:repoRoot "functions\private\Install-WinUtilProgramWinget.ps1")
    . (Join-Path $script:repoRoot "functions\private\Install-WinUtilProgramChoco.ps1")

    function Invoke-WPFUIThread { }
    function Write-WinUtilLog { }
}

Describe "Get-WinUtilSelectedPackages" {
    BeforeEach {
        Mock Invoke-WPFUIThread { }
    }

    It "uses winget IDs when winget is preferred" {
        $packages = @(
            [pscustomobject]@{ winget = "Git.Git"; choco = "git" }
            [pscustomobject]@{ winget = "VideoLAN.VLC"; choco = "vlc" }
        )

        $result = Get-WinUtilSelectedPackages -PackageList $packages -Preference ([PackageManagers]::Winget)

        (@($result[[PackageManagers]::Winget]) -join "|") | Should -Be "Git.Git|VideoLAN.VLC"
        @($result[[PackageManagers]::Choco]).Count | Should -Be 0
    }

    It "uses choco IDs and falls back to winget for na or missing choco IDs" {
        $packages = @(
            [pscustomobject]@{ winget = "Git.Git"; choco = "git" }
            [pscustomobject]@{ winget = "VideoLAN.VLC"; choco = "na" }
            [pscustomobject]@{ winget = "Mozilla.Firefox" }
        )

        $result = Get-WinUtilSelectedPackages -PackageList $packages -Preference ([PackageManagers]::Choco)

        (@($result[[PackageManagers]::Choco]) -join "|") | Should -Be "git"
        (@($result[[PackageManagers]::Winget]) -join "|") | Should -Be "VideoLAN.VLC|Mozilla.Firefox"
    }

    It "skips blank, na, and missing package IDs" {
        $packages = @(
            [pscustomobject]@{ winget = ""; choco = "" }
            [pscustomobject]@{ winget = "na"; choco = "na" }
            [pscustomobject]@{ choco = "only-choco" }
            [pscustomobject]@{ winget = "   " }
        )

        $result = Get-WinUtilSelectedPackages -PackageList $packages -Preference ([PackageManagers]::Winget)

        @($result[[PackageManagers]::Winget]).Count | Should -Be 0
        @($result[[PackageManagers]::Choco]).Count | Should -Be 0
    }

    It "deduplicates package IDs" {
        $packages = @(
            [pscustomobject]@{ winget = "Git.Git"; choco = "git" }
            [pscustomobject]@{ winget = "Git.Git"; choco = "git" }
            [pscustomobject]@{ winget = "VideoLAN.VLC"; choco = "vlc" }
        )

        $result = Get-WinUtilSelectedPackages -PackageList $packages -Preference ([PackageManagers]::Choco)

        (@($result[[PackageManagers]::Choco]) -join "|") | Should -Be "git|vlc"
        @($result[[PackageManagers]::Winget]).Count | Should -Be 0
    }

    It "returns empty package lists for an empty selection" {
        $result = Get-WinUtilSelectedPackages -PackageList @() -Preference ([PackageManagers]::Winget)

        @($result[[PackageManagers]::Winget]).Count | Should -Be 0
        @($result[[PackageManagers]::Choco]).Count | Should -Be 0
    }
}

Describe "Test-WinUtilPackageManager" {
    BeforeEach {
        Mock Write-Host { }
    }

    It "reports winget installed when the command exists" {
        Mock Get-Command {
            [pscustomobject]@{ Name = "winget" }
        } -ParameterFilter { $Name -eq "winget" -and $ErrorAction -eq "SilentlyContinue" }

        Test-WinUtilPackageManager -winget | Should -Be "installed"

        Should -Invoke -CommandName Get-Command -Times 1 -Exactly -ParameterFilter {
            $Name -eq "winget" -and $ErrorAction -eq "SilentlyContinue"
        }
    }

    It "reports choco not installed when the command is missing" {
        Mock Get-Command {
            $null
        } -ParameterFilter { $Name -eq "choco" -and $ErrorAction -eq "SilentlyContinue" }

        Test-WinUtilPackageManager -choco | Should -Be "not-installed"

        Should -Invoke -CommandName Get-Command -Times 1 -Exactly -ParameterFilter {
            $Name -eq "choco" -and $ErrorAction -eq "SilentlyContinue"
        }
    }
}

Describe "Install-WinUtilProgramWinget" {
    BeforeEach {
        Mock Write-WinUtilLog { }
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }
    }

    It "starts winget with install arguments" {
        Install-WinUtilProgramWinget -Action Install -Programs @("Git.Git")

        Should -Invoke -CommandName Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq "winget" -and
                (@($ArgumentList) -join "|") -eq "install|--id|Git.Git|--accept-package-agreements|--accept-source-agreements|--source|winget|--silent" -and
                $NoNewWindow -eq $true -and
                $Wait -eq $true -and
                $PassThru -eq $true
        }
    }

    It "starts winget with uninstall arguments and msstore source when requested" {
        Install-WinUtilProgramWinget -Action Uninstall -Programs @("msstore:9NBLGGH4NNS1")

        Should -Invoke -CommandName Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq "winget" -and
                (@($ArgumentList) -join "|") -eq "uninstall|--id|9NBLGGH4NNS1|--source|msstore|--silent"
        }
    }

    It "skips whitespace and na package IDs" {
        Install-WinUtilProgramWinget -Action Install -Programs @(" ", "na")

        Should -Invoke -CommandName Start-Process -Times 0 -Exactly
    }
}

Describe "Install-WinUtilProgramChoco" {
    BeforeEach {
        Mock Write-WinUtilLog { }
        Mock Start-Process { [pscustomobject]@{ ExitCode = 0 } }
    }

    It "starts choco with install arguments" {
        Install-WinUtilProgramChoco -Action Install -Programs @("git", "vlc")

        Should -Invoke -CommandName Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq "choco" -and
                $ArgumentList -eq "install git vlc -y" -and
                $NoNewWindow -eq $true -and
                $Wait -eq $true -and
                $PassThru -eq $true
        }
    }

    It "starts choco with uninstall arguments" {
        Install-WinUtilProgramChoco -Action Uninstall -Programs @("git")

        Should -Invoke -CommandName Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq "choco" -and $ArgumentList -eq "uninstall git -y"
        }
    }
}
