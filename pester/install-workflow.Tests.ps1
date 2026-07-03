#===========================================================================
# Tests - Install and Uninstall Workflows
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilPackageLogSummary.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFInstall.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFUnInstall.ps1")

    function Show-WinUtilMessage {
        param($Message, $Title, $Button, $Icon)
    }
    function Invoke-WPFRunspace {
        param($ArgumentList, $ParameterList, [scriptblock]$ScriptBlock)
    }
    function Get-WinUtilSelectedPackages {
        param($PackageList, [string]$Preference)
    }
    function Show-WPFInstallAppBusy {
        param($text)
    }
    function Hide-WPFInstallAppBusy { }
    function Install-WinUtilWinget { }
    function Install-WinUtilChoco { }
    function Install-WinUtilProgramWinget {
        param($Action, $Programs)
    }
    function Install-WinUtilProgramChoco {
        param($Action, $Programs)
    }
    function Invoke-WPFUIThread {
        param([scriptblock]$ScriptBlock)
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

        $script:AppTitle = "Winutil"
        $script:sync = [Hashtable]::Synchronized(@{
            ProcessRunning = $ProcessRunning
            selectedApps = $selectedApps
            preferences = [pscustomobject]@{
                packagemanager = "Winget"
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
        $script:capturedInstallScriptBlock = $null
        $script:capturedInstallParameterList = $null

        Mock Show-WinUtilMessage { "OK" }
        Mock Invoke-WPFRunspace {
            $script:capturedInstallScriptBlock = $ScriptBlock
            $script:capturedInstallParameterList = $ParameterList
            [pscustomobject]@{ MockHandle = $true }
        }
        Mock Write-WinUtilLog { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name AppTitle -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedInstallScriptBlock -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedInstallParameterList -Scope Script -ErrorAction SilentlyContinue
    }

    It "queues selected packages with the configured package manager preference" {
        Invoke-WPFInstall

        Should -Invoke -CommandName Invoke-WPFRunspace -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock -is [scriptblock] -and
                $ParameterList.Count -eq 2 -and
                $ParameterList[0][0] -eq "PackagesToInstall" -and
                @($ParameterList[0][1]).Count -eq 1 -and
                @($ParameterList[0][1])[0].winget -eq "Git.Git" -and
                $ParameterList[1][0] -eq "ManagerPreference" -and
                $ParameterList[1][1] -eq "Winget"
        }
        Should -Invoke -CommandName Show-WinUtilMessage -Times 0 -Exactly
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Component -eq "Install" -and
                $Message -eq "Install selected package(s): Git (winget: Git.Git)"
        }
    }

    It "prompts and exits when no packages are selected" {
        New-WinUtilInstallTestContext

        Invoke-WPFInstall

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "Please select the program(s) to install or upgrade." -and
                $Title -eq "Winutil" -and
                $Button -eq "OK" -and
                $Icon -eq "Warning"
        }
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 0 -Exactly
    }

    It "prompts and exits when another install process is running" {
        New-WinUtilInstallTestContext -ProcessRunning $true -Packages @($script:package)

        Invoke-WPFInstall

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "[Invoke-WPFInstall] An Install process is currently running." -and
                $Title -eq "Winutil" -and
                $Button -eq "OK" -and
                $Icon -eq "Warning"
        }
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 0 -Exactly
    }
}

Describe "Invoke-WPFInstall runspace body" {
    BeforeEach {
        $script:package = New-WinUtilPackage
        New-WinUtilInstallTestContext -Packages @($script:package)
        $script:capturedInstallScriptBlock = $null

        Mock Show-WinUtilMessage { "OK" }
        Mock Invoke-WPFRunspace {
            $script:capturedInstallScriptBlock = $ScriptBlock
            [pscustomobject]@{ MockHandle = $true }
        }
        Mock Get-WinUtilSelectedPackages {
            New-WinUtilPackageSplit -Winget @("Git.Git") -Choco @("vlc")
        }
        Mock Show-WPFInstallAppBusy { }
        Mock Hide-WPFInstallAppBusy { }
        Mock Install-WinUtilWinget { }
        Mock Install-WinUtilChoco { }
        Mock Install-WinUtilProgramWinget { }
        Mock Install-WinUtilProgramChoco { }
        Mock Invoke-WPFUIThread { }
        Mock Write-WinUtilLog { }
        Mock Write-Host { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name AppTitle -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedInstallScriptBlock -Scope Script -ErrorAction SilentlyContinue
    }

    It "installs split winget and choco packages and cleans up on success" {
        Invoke-WPFInstall

        & $script:capturedInstallScriptBlock -PackagesToInstall @($script:package) -ManagerPreference "Winget"

        Should -Invoke -CommandName Get-WinUtilSelectedPackages -Times 1 -Exactly -ParameterFilter {
            @($PackageList).Count -eq 1 -and $Preference -eq "Winget"
        }
        Should -Invoke -CommandName Show-WPFInstallAppBusy -Times 1 -Exactly -ParameterFilter {
            $text -eq "Installing apps..."
        }
        Should -Invoke -CommandName Install-WinUtilWinget -Times 1 -Exactly
        Should -Invoke -CommandName Install-WinUtilProgramWinget -Times 1 -Exactly -ParameterFilter {
            $Action -eq "Install" -and @($Programs)[0] -eq "Git.Git"
        }
        Should -Invoke -CommandName Install-WinUtilChoco -Times 1 -Exactly
        Should -Invoke -CommandName Install-WinUtilProgramChoco -Times 1 -Exactly -ParameterFilter {
            $Action -eq "Install" -and @($Programs)[0] -eq "vlc"
        }
        Should -Invoke -CommandName Hide-WPFInstallAppBusy -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-WPFUIThread -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.ToString() -like '*Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"*'
        }
        $script:sync.ProcessRunning | Should -BeFalse
    }

    It "hides the busy overlay, sets taskbar error state, and clears ProcessRunning on failure" {
        Mock Install-WinUtilProgramWinget { throw "winget failed" }

        Invoke-WPFInstall

        & $script:capturedInstallScriptBlock -PackagesToInstall @($script:package) -ManagerPreference "Winget"

        Should -Invoke -CommandName Hide-WPFInstallAppBusy -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-WPFUIThread -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.ToString() -like '*Set-WinUtilTaskbaritem -state "Error" -overlay "warning"*'
        }
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and $Component -eq "Install" -and $Message -like "Install workflow failed:*"
        }
        $script:sync.ProcessRunning | Should -BeFalse
    }
}

Describe "Invoke-WPFUnInstall entrypoint" {
    BeforeEach {
        $script:package = New-WinUtilPackage
        New-WinUtilInstallTestContext -Packages @($script:package)
        $script:capturedUninstallScriptBlock = $null
        $script:capturedUninstallParameterList = $null

        Mock Show-WinUtilMessage { "Yes" }
        Mock Invoke-WPFRunspace {
            $script:capturedUninstallScriptBlock = $ScriptBlock
            $script:capturedUninstallParameterList = $ParameterList
            [pscustomobject]@{ MockHandle = $true }
        }
        Mock Write-WinUtilLog { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name AppTitle -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedUninstallScriptBlock -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedUninstallParameterList -Scope Script -ErrorAction SilentlyContinue
    }

    It "confirms and queues selected packages with the configured package manager preference" {
        Invoke-WPFUnInstall -PackagesToUninstall @($script:package)

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -like "*This will uninstall the following applications:*" -and
                $Message -like "*Git*" -and
                $Title -eq "Are you sure?" -and
                "$Button" -eq "YesNo" -and
                "$Icon" -eq "Information"
        }
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock -is [scriptblock] -and
                $ParameterList.Count -eq 2 -and
                $ParameterList[0][0] -eq "PackagesToUninstall" -and
                @($ParameterList[0][1]).Count -eq 1 -and
                @($ParameterList[0][1])[0].winget -eq "Git.Git" -and
                $ParameterList[1][0] -eq "ManagerPreference" -and
                $ParameterList[1][1] -eq "Winget"
        }
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Component -eq "Uninstall" -and
                $Message -eq "Uninstall selected package(s): Git (winget: Git.Git)"
        }
    }

    It "prompts and exits when no packages are selected" {
        Invoke-WPFUnInstall -PackagesToUninstall @()

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "Please select the program(s) to uninstall" -and
                $Title -eq "Winutil" -and
                $Button -eq "OK" -and
                $Icon -eq "Warning"
        }
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 0 -Exactly
    }

    It "prompts and exits when another install process is running" {
        $script:sync.ProcessRunning = $true

        Invoke-WPFUnInstall -PackagesToUninstall @($script:package)

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "[Invoke-WPFUnInstall] Install process is currently running" -and
                $Title -eq "Winutil" -and
                $Button -eq "OK" -and
                $Icon -eq "Warning"
        }
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 0 -Exactly
    }

    It "exits without queueing uninstall when confirmation is declined" {
        Mock Show-WinUtilMessage { "No" } -ParameterFilter { $Title -eq "Are you sure?" }

        Invoke-WPFUnInstall -PackagesToUninstall @($script:package)

        Should -Invoke -CommandName Invoke-WPFRunspace -Times 0 -Exactly
    }
}

Describe "Invoke-WPFUnInstall runspace body" {
    BeforeEach {
        $script:package = New-WinUtilPackage
        New-WinUtilInstallTestContext -Packages @($script:package)
        $script:capturedUninstallScriptBlock = $null

        Mock Show-WinUtilMessage { "Yes" }
        Mock Invoke-WPFRunspace {
            $script:capturedUninstallScriptBlock = $ScriptBlock
            [pscustomobject]@{ MockHandle = $true }
        }
        Mock Get-WinUtilSelectedPackages {
            New-WinUtilPackageSplit -Winget @("Git.Git") -Choco @("vlc")
        }
        Mock Show-WPFInstallAppBusy { }
        Mock Hide-WPFInstallAppBusy { }
        Mock Install-WinUtilProgramWinget { }
        Mock Install-WinUtilProgramChoco { }
        Mock Invoke-WPFUIThread { }
        Mock Write-WinUtilLog { }
        Mock Write-Host { }
        Mock New-Item { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name AppTitle -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedUninstallScriptBlock -Scope Script -ErrorAction SilentlyContinue
    }

    It "uninstalls split winget and choco packages and cleans up on success" {
        Invoke-WPFUnInstall -PackagesToUninstall @($script:package)

        & $script:capturedUninstallScriptBlock -PackagesToUninstall @($script:package) -ManagerPreference "Winget"

        Should -Invoke -CommandName Get-WinUtilSelectedPackages -Times 1 -Exactly -ParameterFilter {
            @($PackageList).Count -eq 1 -and $Preference -eq "Winget"
        }
        Should -Invoke -CommandName Show-WPFInstallAppBusy -Times 1 -Exactly -ParameterFilter {
            $text -eq "Uninstalling apps..."
        }
        Should -Invoke -CommandName Install-WinUtilProgramWinget -Times 1 -Exactly -ParameterFilter {
            $Action -eq "Uninstall" -and @($Programs)[0] -eq "Git.Git"
        }
        Should -Invoke -CommandName Install-WinUtilProgramChoco -Times 1 -Exactly -ParameterFilter {
            $Action -eq "Uninstall" -and @($Programs)[0] -eq "vlc"
        }
        Should -Invoke -CommandName Hide-WPFInstallAppBusy -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-WPFUIThread -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.ToString() -like '*Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"*'
        }
        $script:sync.ProcessRunning | Should -BeFalse
    }

    It "hides the busy overlay, sets taskbar error state, and clears ProcessRunning on failure" {
        Mock Install-WinUtilProgramWinget { throw "winget failed" }

        Invoke-WPFUnInstall -PackagesToUninstall @($script:package)

        & $script:capturedUninstallScriptBlock -PackagesToUninstall @($script:package) -ManagerPreference "Winget"

        Should -Invoke -CommandName Hide-WPFInstallAppBusy -Times 1 -Exactly
        Should -Invoke -CommandName Invoke-WPFUIThread -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.ToString() -like '*Set-WinUtilTaskbaritem -state "Error" -overlay "warning"*'
        }
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and $Component -eq "Uninstall" -and $Message -like "Uninstall workflow failed:*"
        }
        $script:sync.ProcessRunning | Should -BeFalse
    }
}
