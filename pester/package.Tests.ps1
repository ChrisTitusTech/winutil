#===========================================================================
# Tests - Package Selection and Package Managers
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilSelectedPackages.ps1")
    . (Join-Path $script:repoRoot "functions\private\Test-WinUtilPackageManager.ps1")
    . (Join-Path $script:repoRoot "functions\private\Install-WinUtilProgramWinget.ps1")
    . (Join-Path $script:repoRoot "functions\private\Install-WinUtilProgramChoco.ps1")

    function Invoke-WPFUIThread { }
    function Write-WinUtilJobBanner {
        param([string]$Message, [string]$Level)
    }
    # The CLI path is what these tests cover; the module path is verified against real winget
    function Step-WinUtilJob { param([string]$Status, [int]$Percent, [string]$State, [string]$Overlay, [switch]$Hide) }
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

        $result = Get-WinUtilSelectedPackages -PackageList $packages -Preference "Winget"

        (@($result["Winget"]) -join "|") | Should -Be "Git.Git|VideoLAN.VLC"
        @($result["Choco"]).Count | Should -Be 0
    }

    It "uses choco IDs and falls back to winget for na or missing choco IDs" {
        $packages = @(
            [pscustomobject]@{ winget = "Git.Git"; choco = "git" }
            [pscustomobject]@{ winget = "VideoLAN.VLC"; choco = "na" }
            [pscustomobject]@{ winget = "Mozilla.Firefox" }
        )

        $result = Get-WinUtilSelectedPackages -PackageList $packages -Preference "Choco"

        (@($result["Choco"]) -join "|") | Should -Be "git"
        (@($result["Winget"]) -join "|") | Should -Be "VideoLAN.VLC|Mozilla.Firefox"
    }

    It "skips blank, na, and missing package IDs" {
        $packages = @(
            [pscustomobject]@{ winget = ""; choco = "" }
            [pscustomobject]@{ winget = "na"; choco = "na" }
            [pscustomobject]@{ choco = "only-choco" }
            [pscustomobject]@{ winget = "   " }
        )

        $result = Get-WinUtilSelectedPackages -PackageList $packages -Preference "Winget"

        @($result["Winget"]).Count | Should -Be 0
        @($result["Choco"]).Count | Should -Be 0
    }

    It "deduplicates package IDs" {
        $packages = @(
            [pscustomobject]@{ winget = "Git.Git"; choco = "git" }
            [pscustomobject]@{ winget = "Git.Git"; choco = "git" }
            [pscustomobject]@{ winget = "VideoLAN.VLC"; choco = "vlc" }
        )

        $result = Get-WinUtilSelectedPackages -PackageList $packages -Preference "Choco"

        (@($result["Choco"]) -join "|") | Should -Be "git|vlc"
        @($result["Winget"]).Count | Should -Be 0
    }

    It "returns exactly one object so the caller can index the split" {
        # A stray value on the output stream would make this an array, and every package list
        # would then read back empty.
        $result = @(Get-WinUtilSelectedPackages -PackageList @([pscustomobject]@{ winget = "Git.Git" }) -Preference "Winget")

        $result.Count | Should -Be 1
        (@($result[0]["Winget"]) -join "|") | Should -Be "Git.Git"
    }

    It "returns empty package lists for an empty selection" {
        $result = Get-WinUtilSelectedPackages -PackageList @() -Preference "Winget"

        @($result["Winget"]).Count | Should -Be 0
        @($result["Choco"]).Count | Should -Be 0
    }
}

Describe "Test-WinUtilPackageManager" {
    BeforeEach {
        Mock Write-WinUtilJobBanner { }
    }

    It "reports winget installed when the command exists" {
        Mock Get-Command {
            [pscustomobject]@{ Name = "winget" }
        } -ParameterFilter { $Name -eq "winget" -and $ErrorAction -eq "SilentlyContinue" }

        Test-WinUtilPackageManager -winget | Should -Be "installed"

        Should -Invoke -CommandName Get-Command -Times 1 -Exactly -ParameterFilter {
            $Name -eq "winget" -and $ErrorAction -eq "SilentlyContinue"
        }
        Should -Invoke -CommandName Write-WinUtilJobBanner -Times 0 -Exactly
    }

    It "reports choco not installed when the command is missing" {
        Mock Get-Command {
            $null
        } -ParameterFilter { $Name -eq "choco" -and $ErrorAction -eq "SilentlyContinue" }

        Test-WinUtilPackageManager -choco | Should -Be "not-installed"

        Should -Invoke -CommandName Get-Command -Times 1 -Exactly -ParameterFilter {
            $Name -eq "choco" -and $ErrorAction -eq "SilentlyContinue"
        }
        Should -Invoke -CommandName Write-WinUtilJobBanner -Times 0 -Exactly
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

    It "upgrades every package through its configured source without parsing the output table" {
        Install-WinUtilProgramWinget -Action Upgrade -Programs @("all")

        Should -Invoke -CommandName Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq "winget" -and
                (@($ArgumentList) -join "|") -eq "upgrade|--all|--accept-package-agreements|--accept-source-agreements|--include-unknown|--silent"
        }
    }

    It "skips whitespace and na package IDs" {
        Install-WinUtilProgramWinget -Action Install -Programs @(" ", "na")

        Should -Invoke -CommandName Start-Process -Times 0 -Exactly
    }
}

Describe "Install-WinUtilProgramChoco" {
    BeforeAll {
        # choco is a native command, so it needs a function to stand in for it
        function choco { $global:LASTEXITCODE = 0 }
    }

    BeforeEach {
        Mock Write-WinUtilLog { }
        Mock Step-WinUtilJob { }
        Mock choco { $global:LASTEXITCODE = 0 }
    }

    It "calls choco once per package so a failure names the one that failed" {
        $results = @(Install-WinUtilProgramChoco -Action Install -Programs @("git", "vlc"))

        $results.Count | Should -Be 2
        $results[0].Package | Should -Be "git"
        $results[1].Package | Should -Be "vlc"
        Should -Invoke -CommandName choco -Times 2 -Exactly
    }

    It "passes the install verb and suppresses choco's own progress redraw" {
        Install-WinUtilProgramChoco -Action Install -Programs @("git")

        Should -Invoke -CommandName choco -Times 1 -Exactly -ParameterFilter {
            $args -contains "install" -and $args -contains "git" -and
                $args -contains "-y" -and $args -contains "--no-progress"
        }
    }

    It "passes the uninstall verb" {
        Install-WinUtilProgramChoco -Action Uninstall -Programs @("git")

        Should -Invoke -CommandName choco -Times 1 -Exactly -ParameterFilter {
            $args -contains "uninstall" -and $args -contains "git"
        }
    }

    It "upgrades rather than installing when asked to upgrade" {
        # choco install all -y would look for a package called "all"
        Install-WinUtilProgramChoco -Action Upgrade -Programs @("all")

        Should -Invoke -CommandName choco -Times 1 -Exactly -ParameterFilter {
            $args -contains "upgrade" -and $args -contains "all"
        }
    }

    It "moves the progress bar through the list" {
        Install-WinUtilProgramChoco -Action Install -Programs @("git", "vlc") -ProgressBase 0 -ProgressSpan 100

        Should -Invoke -CommandName Step-WinUtilJob -ParameterFilter { $Status -like "*git (1/2)*" }
        Should -Invoke -CommandName Step-WinUtilJob -ParameterFilter { $Status -like "*vlc (2/2)*" }
    }
}
