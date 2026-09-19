#===========================================================================
# Tests - Install and Uninstall Workflows
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Measure-WinUtilStep.ps1")

    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilPackageLogSummary.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFInstall.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFUnInstall.ps1")

    function Show-WinUtilMessage {
        param($Message, $Title, $Button, $Icon)
    }
    function Start-WinUtilJob {
        param(
            [string]$Name,
            [scriptblock]$ScriptBlock,
            [hashtable]$Parameters,
            [string]$Description,
            [switch]$DisableAppList
        )
    }
    function Step-WinUtilJob {
        param([string]$Status, [int]$Percent, [string]$State, [string]$Overlay)
    }
    function Invoke-WPFRunspace {
        param($ArgumentList, $ParameterList, [scriptblock]$ScriptBlock)
    }
    function Get-WinUtilSelectedPackages {
        param($PackageList, [string]$Preference)
    }
    function Install-WinUtilWinget { }
    function Install-WinUtilChoco { }
    function Install-WinUtilProgramWinget {
        param($Action, $Programs)
    }
    function Install-WinUtilProgramChoco {
        param($Action, $Programs)
    }
    function Complete-WinUtilPackageRun {
        param([string]$Action, [object[]]$Results)
    }
    function Invoke-WPFUIThread {
        param([scriptblock]$ScriptBlock, [hashtable]$Parameters, [switch]$Async)
    }
    function Write-WinUtilLog {
        param($Message, $Level, $Component)
    }

    function script:New-WinUtilPackage {
        param(
            [string]$Name = "Git",
            [string]$Winget = "Git.Git",
            [string]$Choco = "git"
        )

        [pscustomobject]@{
            Name = $Name
            Description = "$Name package"
            winget = $Winget
            choco = $Choco
        }
    }

    function script:New-WinUtilInstallTestContext {
        param(
            [bool]$ProcessRunning = $false,
            [object[]]$Packages = @()
        )

        $applications = @{}
        $selectedApps = [System.Collections.Generic.List[string]]::new()

        for ($i = 0; $i -lt $Packages.Count; $i++) {
            $key = "WPFInstallTest$i"
            $applications[$key] = $Packages[$i]
            $selectedApps.Add($key)
        }

        $script:sync = [Hashtable]::Synchronized(@{
            ProcessRunning = $ProcessRunning
            selectedApps = $selectedApps
            preferences = [pscustomobject]@{
                packagemanager = "Winget"
            }
            Form = [pscustomobject]@{
                Dispatcher = [pscustomobject]@{}
            }
            configs = @{
                applicationsHashtable = $applications
            }
        })
    }

    function script:New-WinUtilPackageSplit {
        param(
            [string[]]$Winget = @(),
            [string[]]$Choco = @()
        )

        $packages = @{}
        $packages["Winget"] = [System.Collections.Generic.List[string]]::new()
        $packages["Choco"] = [System.Collections.Generic.List[string]]::new()

        foreach ($package in $Winget) {
            $null = $packages["Winget"].Add($package)
        }

        foreach ($package in $Choco) {
            $null = $packages["Choco"].Add($package)
        }

        $packages
    }
}

Describe "Invoke-WPFInstall entrypoint" {
    BeforeEach {
        $script:package = New-WinUtilPackage
        New-WinUtilInstallTestContext -Packages @($script:package)
        $script:capturedInstallJob = $null

        Mock Show-WinUtilMessage { "OK" }
        Mock Start-WinUtilJob {
            $script:capturedInstallJob = [pscustomobject]@{
                Name = $Name
                ScriptBlock = $ScriptBlock
                Parameters = $Parameters
                Description = $Description
                DisableAppList = [bool]$DisableAppList
            }
        }
        Mock Write-WinUtilLog { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedInstallJob -Scope Script -ErrorAction SilentlyContinue
    }

    It "queues an install job with the configured package manager preference" {
        Invoke-WPFInstall

        Should -Invoke -CommandName Start-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Name -eq "Install" -and
                $ScriptBlock -is [scriptblock] -and
                $DisableAppList -and
                @($Parameters.PackagesToInstall).Count -eq 1 -and
                @($Parameters.PackagesToInstall)[0].winget -eq "Git.Git" -and
                $Parameters.ManagerPreference -eq "Winget"
        }
        Should -Invoke -CommandName Show-WinUtilMessage -Times 0 -Exactly
    }

    It "logs package identities before the job is queued" {
        Invoke-WPFInstall

        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Component -eq "Install" -and
                $Message -eq "Install selected package(s): Git (winget: Git.Git)"
        }
    }

    It "queues the explicit app popup package over the selected apps" {
        $explicitPackage = New-WinUtilPackage -Name "VLC" -Winget "VideoLAN.VLC" -Choco "vlc"

        Invoke-WPFInstall -PackagesToInstall $explicitPackage

        Should -Invoke -CommandName Start-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            @($Parameters.PackagesToInstall).Count -eq 1 -and
                @($Parameters.PackagesToInstall)[0].winget -eq "VideoLAN.VLC"
        }
        Should -Invoke -CommandName Show-WinUtilMessage -Times 0 -Exactly
    }

    It "prompts and exits when no packages are selected" {
        New-WinUtilInstallTestContext

        Invoke-WPFInstall

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "Please select the program(s) to install or upgrade." -and
                $Title -eq "WinUtil" -and
                $Button -eq "OK" -and
                $Icon -eq "Warning"
        }
        Should -Invoke -CommandName Start-WinUtilJob -Times 0 -Exactly
    }
}

Describe "Invoke-WPFInstall job body" {
    BeforeEach {
        $script:package = New-WinUtilPackage
        New-WinUtilInstallTestContext -Packages @($script:package)
        $script:capturedInstallJob = $null

        Mock Show-WinUtilMessage { "OK" }
        Mock Start-WinUtilJob {
            $script:capturedInstallJob = [pscustomobject]@{
                ScriptBlock = $ScriptBlock
                Parameters = $Parameters
            }
        }
        Mock Get-WinUtilSelectedPackages {
            New-WinUtilPackageSplit -Winget @("Git.Git") -Choco @("vlc")
        }
        Mock Step-WinUtilJob { }
        Mock Install-WinUtilWinget { }
        Mock Install-WinUtilChoco { }
        Mock Install-WinUtilProgramWinget { }
        Mock Install-WinUtilProgramChoco { }
        Mock Write-WinUtilLog { }
        Mock Write-Host { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedInstallJob -Scope Script -ErrorAction SilentlyContinue
    }

    It "installs split winget and choco packages and reports progress" {
        Invoke-WPFInstall

        $jobParameters = $script:capturedInstallJob.Parameters
        & $script:capturedInstallJob.ScriptBlock @jobParameters

        Should -Invoke -CommandName Get-WinUtilSelectedPackages -Times 1 -Exactly -ParameterFilter {
            @($PackageList).Count -eq 1 -and $Preference -eq "Winget"
        }
        Should -Invoke -CommandName Install-WinUtilWinget -Times 1 -Exactly
        Should -Invoke -CommandName Install-WinUtilProgramWinget -Times 1 -Exactly -ParameterFilter {
            $Action -eq "Install" -and @($Programs)[0] -eq "Git.Git"
        }
        Should -Invoke -CommandName Install-WinUtilChoco -Times 1 -Exactly
        Should -Invoke -CommandName Install-WinUtilProgramChoco -Times 1 -Exactly -ParameterFilter {
            $Action -eq "Install" -and @($Programs)[0] -eq "vlc"
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Installed Git.Git (1/2)" -and $Percent -eq 50
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Installed Chocolatey packages (2/2)" -and $Percent -eq 100
        }
    }

    It "lets a failure surface so the job layer can handle it" {
        Mock Install-WinUtilProgramWinget { throw "winget failed" }

        Invoke-WPFInstall

        { $jobParameters = $script:capturedInstallJob.Parameters
        & $script:capturedInstallJob.ScriptBlock @jobParameters } |
            Should -Throw "winget failed"
    }
}

Describe "Invoke-WPFUnInstall entrypoint" {
    BeforeEach {
        $script:package = New-WinUtilPackage
        New-WinUtilInstallTestContext -Packages @($script:package)
        $script:capturedUninstallJob = $null

        Mock Show-WinUtilMessage { "Yes" }
        Mock Start-WinUtilJob {
            $script:capturedUninstallJob = [pscustomobject]@{
                Name = $Name
                ScriptBlock = $ScriptBlock
                Parameters = $Parameters
                DisableAppList = [bool]$DisableAppList
            }
        }
        Mock Write-WinUtilLog { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedUninstallJob -Scope Script -ErrorAction SilentlyContinue
    }

    It "confirms and queues an uninstall job with the configured package manager preference" {
        Invoke-WPFUnInstall

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Title -eq "Are you sure?" -and $Button -eq "YesNo"
        }
        Should -Invoke -CommandName Start-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Name -eq "Uninstall" -and
                $ScriptBlock -is [scriptblock] -and
                $DisableAppList -and
                @($Parameters.PackagesToUninstall).Count -eq 1 -and
                @($Parameters.PackagesToUninstall)[0].winget -eq "Git.Git" -and
                $Parameters.ManagerPreference -eq "Winget"
        }
    }

    It "logs package identities before the uninstall job is queued" {
        Invoke-WPFUnInstall

        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Component -eq "Uninstall" -and
                $Message -eq "Uninstall selected package(s): Git (winget: Git.Git)"
        }
    }

    It "prompts and exits when no packages are selected" {
        New-WinUtilInstallTestContext

        Invoke-WPFUnInstall

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "Please select the program(s) to uninstall"
        }
        Should -Invoke -CommandName Start-WinUtilJob -Times 0 -Exactly
    }

    It "exits without queueing uninstall when confirmation is declined" {
        Mock Show-WinUtilMessage { "No" }

        Invoke-WPFUnInstall

        Should -Invoke -CommandName Start-WinUtilJob -Times 0 -Exactly
    }
}

Describe "Invoke-WPFUnInstall job body" {
    BeforeEach {
        $script:package = New-WinUtilPackage
        New-WinUtilInstallTestContext -Packages @($script:package)
        $script:capturedUninstallJob = $null

        Mock Show-WinUtilMessage { "Yes" }
        Mock Start-WinUtilJob {
            $script:capturedUninstallJob = [pscustomobject]@{
                ScriptBlock = $ScriptBlock
                Parameters = $Parameters
            }
        }
        Mock Get-WinUtilSelectedPackages {
            New-WinUtilPackageSplit -Winget @("Git.Git") -Choco @("vlc")
        }
        Mock Step-WinUtilJob { }
        Mock Install-WinUtilProgramWinget { }
        Mock Install-WinUtilProgramChoco { }
        Mock Write-WinUtilLog { }
        Mock Write-Host { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedUninstallJob -Scope Script -ErrorAction SilentlyContinue
    }

    It "uninstalls split winget and choco packages and reports progress" {
        Invoke-WPFUnInstall

        $jobParameters = $script:capturedUninstallJob.Parameters
        & $script:capturedUninstallJob.ScriptBlock @jobParameters

        Should -Invoke -CommandName Install-WinUtilProgramWinget -Times 1 -Exactly -ParameterFilter {
            $Action -eq "Uninstall" -and @($Programs)[0] -eq "Git.Git"
        }
        Should -Invoke -CommandName Install-WinUtilProgramChoco -Times 1 -Exactly -ParameterFilter {
            $Action -eq "Uninstall" -and @($Programs)[0] -eq "vlc"
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Uninstalled Git.Git (1/2)" -and $Percent -eq 50
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Uninstalled Chocolatey packages (2/2)" -and $Percent -eq 100
        }
    }

    It "lets a failure surface so the job layer can handle it" {
        Mock Install-WinUtilProgramWinget { throw "winget failed" }

        Invoke-WPFUnInstall

        $jobParameters = $script:capturedUninstallJob.Parameters
        { & $script:capturedUninstallJob.ScriptBlock @jobParameters } | Should -Throw "winget failed"
    }
}
