#===========================================================================
# Tests - AppX Management
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilInstalledAPPX.ps1")
    . (Join-Path $script:repoRoot "functions\private\Install-WinUtilAPPX.ps1")
    . (Join-Path $script:repoRoot "functions\private\Remove-WinUtilAPPX.ps1")
    . (Join-Path $script:repoRoot "functions\private\Remove-WinUtilProvisionedAPPX.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFAppxInstall.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFAppxRemoval.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFButton.ps1")

    $tokens = $null
    $parseErrors = $null
    $provisionedSourcePath = Join-Path $script:repoRoot "functions\private\Remove-WinUtilProvisionedAPPX.ps1"
    $provisionedSourceAst = [System.Management.Automation.Language.Parser]::ParseFile($provisionedSourcePath, [ref]$tokens, [ref]$parseErrors)
    $ps5CommandAssignment = $provisionedSourceAst.Find({
        param($node)
        $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
            $node.Left -is [System.Management.Automation.Language.VariableExpressionAst] -and
            $node.Left.VariablePath.UserPath -eq "ps5Command"
    }, $true)
    $script:provisionedRemovalScriptBlock = $ps5CommandAssignment.Right.Expression.ScriptBlock.GetScriptBlock()

    $installSourcePath = Join-Path $script:repoRoot "functions\private\Install-WinUtilAPPX.ps1"
    $installSourceAst = [System.Management.Automation.Language.Parser]::ParseFile($installSourcePath, [ref]$tokens, [ref]$parseErrors)
    $installCommandAssignment = $installSourceAst.Find({
        param($node)
        $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
            $node.Left -is [System.Management.Automation.Language.VariableExpressionAst] -and
            $node.Left.VariablePath.UserPath -eq "ps5Command"
    }, $true)
    $script:appxInstallScriptBlock = $installCommandAssignment.Right.Expression.ScriptBlock.GetScriptBlock()

    function Write-WinUtilLog {
        param($Message, $Level, $Component)
    }
    function Show-WinUtilMessage {
        param($Message, $Title, $Button, $Icon)
    }
    function Invoke-WPFRunspace {
        param($ArgumentList, $ParameterList, [scriptblock]$ScriptBlock)
    }
    function Invoke-WPFUIThread {
        param([scriptblock]$ScriptBlock)
    }
    function Set-WinUtilProgressBar {
        param($Label, $Percent)
    }
    function Set-WinUtilTweaksProgressIndicator {
        param($Visible, $Label, $Percent)
    }
    function powershell.exe { }
    function Get-AppxPackage {
        param($Name, [switch]$AllUsers, $ErrorAction)
    }
    function Add-AppxPackage {
        param($Register, [switch]$DisableDevelopmentMode, $ErrorAction)
    }
    function Install-WinUtilWinget { }
    function Install-WinUtilProgramWinget {
        param($Action, $Programs)
    }
    function Remove-AppxPackage {
        param(
            [Parameter(ValueFromPipeline = $true)]
            $InputObject,
            $Package,
            [switch]$AllUsers,
            $ErrorAction
        )
        process { }
    }
    function Remove-WinUtilProvisionedAPPX {
        param($PackageList)
    }
    function Get-AppxProvisionedPackage {
        param([switch]$Online, $ErrorAction)
    }
    function Remove-AppxProvisionedPackage {
        param(
            [Parameter(ValueFromPipeline = $true)]
            $InputObject,
            [switch]$Online,
            $PackageName,
            $ErrorAction
        )
        process { }
    }
    function Get-Package {
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification='Test shim is intentionally mocked by Pester.')]
        param($Name, $ErrorAction)
    }
    function Uninstall-Package {
        [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification='Test shim is intentionally mocked by Pester.')]
        param(
            [Parameter(ValueFromPipeline = $true)]
            $InputObject,
            [switch]$Force
        )
        process { }
    }
}

Describe "Get-WinUtilInstalledAPPX" {
    BeforeEach {
        Mock Write-WinUtilLog { }
        Mock powershell.exe {
            $global:LASTEXITCODE = 0
            @("Example.One", "Example.Two")
        }
    }

    It "queries installed package names through Windows PowerShell" {
        $result = Get-WinUtilInstalledAPPX

        $result | Should -Be @("Example.One", "Example.Two")
        Should -Invoke -CommandName powershell.exe -Times 1 -Exactly
        Should -Invoke -CommandName Write-WinUtilLog -Times 0 -Exactly
    }

    It "logs query failures and returns no package names" {
        Mock powershell.exe {
            $global:LASTEXITCODE = 1
            "AppX query failed"
        }

        $result = @(Get-WinUtilInstalledAPPX)

        $result | Should -HaveCount 0
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and
                $Component -eq "AppX" -and
                $Message -eq "Failed to get installed AppX packages: AppX query failed"
        }
    }
}

Describe "Install-WinUtilAPPX" {
    BeforeEach {
        Mock Write-WinUtilLog { }
        Mock Install-WinUtilWinget { }
        Mock Install-WinUtilProgramWinget { }
        Mock powershell.exe {
            $global:LASTEXITCODE = 0
            "C:\Program Files\WindowsApps\Example.Package\AppxManifest.xml"
        }
    }

    It "uses a local manifest without contacting the Microsoft Store" {
        Install-WinUtilAPPX -Name "Example.Package" -StoreId "9EXAMPLE1234"

        Should -Invoke -CommandName Install-WinUtilWinget -Times 0 -Exactly
        Should -Invoke -CommandName Install-WinUtilProgramWinget -Times 0 -Exactly
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Component -eq "AppX" -and
                $Message -like "Registered local AppX manifest for Example.Package*"
        }
    }

    It "falls back to the Microsoft Store when no local manifest is available" {
        Mock powershell.exe { $global:LASTEXITCODE = 0 }

        Install-WinUtilAPPX -Name "Example.Package" -StoreId "9EXAMPLE1234"

        Should -Invoke -CommandName Install-WinUtilWinget -Times 1 -Exactly
        Should -Invoke -CommandName Install-WinUtilProgramWinget -Times 1 -Exactly -ParameterFilter {
            $Action -eq "Install" -and $Programs.Count -eq 1 -and $Programs[0] -eq "msstore:9EXAMPLE1234"
        }
    }

    It "logs local registration failures before using the Microsoft Store" {
        Mock powershell.exe {
            $global:LASTEXITCODE = 1
            "Registration failed"
        }

        Install-WinUtilAPPX -Name "Example.Package" -StoreId "9EXAMPLE1234"

        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "WARN" -and
                $Component -eq "AppX" -and
                $Message -eq "Local AppX registration failed for Example.Package: Registration failed"
        }
        Should -Invoke -CommandName Install-WinUtilProgramWinget -Times 1 -Exactly
    }

    It "throws after logging an error when neither install method is available" {
        Mock powershell.exe { $global:LASTEXITCODE = 0 }

        { Install-WinUtilAPPX -Name "Example.Package" } |
            Should -Throw "Unable to install Example.Package because no local manifest or Microsoft Store ID is available."

        Should -Invoke -CommandName Install-WinUtilProgramWinget -Times 0 -Exactly
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and
                $Component -eq "AppX" -and
                $Message -eq "Unable to install Example.Package because no local manifest or Microsoft Store ID is available."
        }
    }

    It "registers an installed package manifest through Windows PowerShell" {
        Mock Get-AppxPackage {
            [pscustomobject]@{
                InstallLocation = "C:\Program Files\WindowsApps\Example.Package"
                Version = [version]"2.0.0.0"
            }
        }
        Mock Get-AppxProvisionedPackage { }
        Mock Test-Path { $LiteralPath -eq "C:\Program Files\WindowsApps\Example.Package\AppxManifest.xml" }
        Mock Add-AppxPackage { }

        $result = & $script:appxInstallScriptBlock "Example.Package"

        $result | Should -Be "C:\Program Files\WindowsApps\Example.Package\AppxManifest.xml"
        Should -Invoke -CommandName Get-AppxPackage -Times 1 -Exactly
        Should -Invoke -CommandName Add-AppxPackage -Times 1 -Exactly
    }
}

Describe "Get installed AppX selection" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            ProcessRunning = $false
            configs = @{
                feature = @{}
                appxHashtable = @{
                    WPFAppxExample = [pscustomobject]@{ PackageId = "Example.Package" }
                    WPFAppxMissing = [pscustomobject]@{ PackageId = "Missing.Package" }
                }
            }
            WPFAppxExample = [pscustomobject]@{ IsChecked = $false }
            WPFAppxMissing = [pscustomobject]@{ IsChecked = $false }
        })

        Mock Set-WinUtilProgressBar { }
        Mock Set-WinUtilTweaksProgressIndicator { }
        Mock Get-WinUtilInstalledAPPX { @("Example.Package") }
        Mock Invoke-WPFAppxInstall { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    It "selects configured packages returned by the compatibility-safe query" {
        Invoke-WPFButton -Button "WPFGetInstalledAppx"

        Should -Invoke -CommandName Get-WinUtilInstalledAPPX -Times 1 -Exactly
        $script:sync.WPFAppxExample.IsChecked | Should -BeTrue
        $script:sync.WPFAppxMissing.IsChecked | Should -BeFalse
    }

    It "routes the install button to the AppX install workflow" {
        Invoke-WPFButton -Button "WPFInstallSelectedAppx"

        Should -Invoke -CommandName Invoke-WPFAppxInstall -Times 1 -Exactly
    }
}

Describe "Remove-WinUtilAPPX" {
    BeforeEach {
        Mock Write-Host { }
        Mock Write-WinUtilLog { }
        Mock Get-AppxPackage {
            @(
                [pscustomobject]@{
                    Name = $Name
                    PackageFullName = "$Name.FullName"
                }
                [pscustomobject]@{
                    Name = $Name
                    PackageFullName = "$Name.FullName"
                }
            )
        }
        Mock Remove-AppxPackage { }
    }

    It "removes matching installed AppX packages" {
        Remove-WinUtilAPPX -Name "Microsoft.Xbox*"

        Should -Invoke -CommandName Get-AppxPackage -Times 1 -Exactly -ParameterFilter {
            $Name -eq "*Microsoft.Xbox**" -and $AllUsers -eq $true
        }
        Should -Invoke -CommandName Remove-AppxPackage -Times 1 -Exactly -ParameterFilter {
            $Package -eq "*Microsoft.Xbox**.FullName" -and
                $AllUsers -eq $true -and
                $ErrorAction -eq "Stop"
        }
    }

    It "logs installed AppX removal failures" {
        Mock Remove-AppxPackage { throw "Removal failed" }

        { Remove-WinUtilAPPX -Name "Example.Package" } | Should -Not -Throw

        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and
                $Component -eq "AppX" -and
                $Message -eq "Failed to remove AppX package *Example.Package*.FullName: Removal failed"
        }
    }
}

Describe "Remove-WinUtilProvisionedAPPX" {
    BeforeEach {
        Mock Get-AppxProvisionedPackage {
            @(
                [pscustomobject]@{ DisplayName = "Example.One"; PackageName = "Example.One_1.0" }
                [pscustomobject]@{ DisplayName = "Example.Two"; PackageName = "Example.Two_1.0" }
            )
        }
        Mock Remove-AppxProvisionedPackage { }
    }

    It "queries provisioned packages once for all selected package names" {
        & $script:provisionedRemovalScriptBlock "Example.One" "Example.Two"

        Should -Invoke -CommandName Get-AppxProvisionedPackage -Times 1 -Exactly -ParameterFilter {
            $Online -eq $true
        }
        Should -Invoke -CommandName Remove-AppxProvisionedPackage -Times 1 -Exactly -ParameterFilter {
            $PackageName -eq "Example.One_1.0" -and $Online -eq $true
        }
        Should -Invoke -CommandName Remove-AppxProvisionedPackage -Times 1 -Exactly -ParameterFilter {
            $PackageName -eq "Example.Two_1.0" -and $Online -eq $true
        }
    }

    It "surfaces provisioned package removal failures from the child process" {
        Mock Remove-AppxProvisionedPackage { throw "DISM failed" }

        { & $script:provisionedRemovalScriptBlock "Example.One" } |
            Should -Throw "*Failed to remove provisioned AppX package Example.One_1.0: DISM failed*"
        Should -Invoke -CommandName Remove-AppxProvisionedPackage -Times 1 -Exactly -ParameterFilter {
            $PackageName -eq "Example.One_1.0" -and
                $Online -eq $true -and
                $ErrorAction -eq "Stop"
        }
    }

    It "throws after logging child process failures" {
        $source = Get-Content -Path $provisionedSourcePath -Raw

        $source | Should -Match '\$removalOutput = powershell\.exe .* 2>&1'
        $source | Should -Match 'Write-WinUtilLog -Level "ERROR" -Component "AppX" -Message \$errorMessage'
        $source | Should -Match '(?s)AppX provisioned package removal failed:.*throw \$errorMessage.*AppX provisioned package removal completed\.'
    }
}

Describe "Invoke-WPFAppxInstall" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            ProcessRunning = $false
            Form = [pscustomobject]@{ Dispatcher = [pscustomobject]@{} }
            selectedAppx = [System.Collections.Generic.List[string]]::new()
            configs = @{
                appxHashtable = @{
                    WPFAppxExample = [pscustomobject]@{
                        Content = "Example App"
                        PackageId = "Example.Package"
                        StoreId = "9EXAMPLE1234"
                    }
                }
            }
        })
        $script:capturedAppxInstallScriptBlock = $null
        $script:capturedAppxInstallParameterList = $null
        $script:appxInstallProcessRunningAtLaunch = $null

        Mock Show-WinUtilMessage { "OK" }
        Mock Write-Host { }
        Mock Write-WinUtilLog { }
        Mock Set-WinUtilTweaksProgressIndicator { }
        Mock Invoke-WPFUIThread { }
        Mock Install-WinUtilAPPX { }
        Mock Invoke-WPFRunspace {
            $script:appxInstallProcessRunningAtLaunch = $script:sync.ProcessRunning
            $script:capturedAppxInstallScriptBlock = $ScriptBlock
            $script:capturedAppxInstallParameterList = $ParameterList
            [pscustomobject]@{ MockHandle = $true }
        }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedAppxInstallScriptBlock -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedAppxInstallParameterList -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name appxInstallProcessRunningAtLaunch -Scope Script -ErrorAction SilentlyContinue
    }

    It "prompts and exits when no AppX packages are selected for install" {
        Invoke-WPFAppxInstall

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "No AppX Package selected" -and
                $Title -eq "Error" -and
                $Button -eq "OK" -and
                $Icon -eq "Error"
        }
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 0 -Exactly
    }

    It "prevents overlapping AppX install operations" {
        $script:sync.ProcessRunning = $true
        $script:sync.selectedAppx.Add("WPFAppxExample")

        Invoke-WPFAppxInstall

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "An AppX process is currently running." -and
                $Title -eq "WinUtil" -and
                $Button -eq "OK" -and
                $Icon -eq "Warning"
        }
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 0 -Exactly
    }

    It "installs selected AppX packages with their Store IDs" {
        $script:sync.selectedAppx.Add("WPFAppxExample")

        Invoke-WPFAppxInstall
        $script:appxInstallProcessRunningAtLaunch | Should -BeTrue
        & $script:capturedAppxInstallScriptBlock -selected @("WPFAppxExample") -apps $script:sync.configs.appxHashtable

        $script:capturedAppxInstallParameterList[0][1][0] | Should -Be "WPFAppxExample"
        Should -Invoke -CommandName Install-WinUtilAPPX -Times 1 -Exactly -ParameterFilter {
            $Name -eq "Example.Package" -and $StoreId -eq "9EXAMPLE1234"
        }
        Should -Invoke -CommandName Set-WinUtilTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "Installing Example App (1/1)" -and $Percent -eq 0
        }
        Should -Invoke -CommandName Set-WinUtilTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "Installed Example App (1/1)" -and $Percent -eq 100
        }
        Should -Invoke -CommandName Set-WinUtilTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "AppX install finished" -and $Percent -eq 100
        }
        Should -Invoke -CommandName Invoke-WPFUIThread -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.ToString() -like '*Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"*'
        }
        $script:sync.ProcessRunning | Should -BeFalse
    }

    It "shows failure feedback and clears ProcessRunning when install fails" {
        $script:sync.selectedAppx.Add("WPFAppxExample")
        Mock Install-WinUtilAPPX { throw "Install failed" }

        Invoke-WPFAppxInstall
        & $script:capturedAppxInstallScriptBlock -selected @("WPFAppxExample") -apps $script:sync.configs.appxHashtable

        Should -Invoke -CommandName Set-WinUtilTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "AppX install failed" -and $Percent -eq 100
        }
        Should -Invoke -CommandName Invoke-WPFUIThread -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.ToString() -like '*Set-WinUtilTaskbaritem -state "Error" -overlay "warning"*'
        }
        $script:sync.ProcessRunning | Should -BeFalse
    }
}

Describe "Invoke-WPFAppxRemoval entrypoint" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            ProcessRunning = $false
            selectedAppx = [System.Collections.Generic.List[string]]::new()
            configs = @{
                appxHashtable = @{}
            }
        })
        $script:capturedAppxScriptBlock = $null
        $script:capturedAppxParameterList = $null
        $script:appxRemovalProcessRunningAtLaunch = $null

        Mock Show-WinUtilMessage { "OK" }
        Mock Invoke-WPFRunspace {
            $script:appxRemovalProcessRunningAtLaunch = $script:sync.ProcessRunning
            $script:capturedAppxScriptBlock = $ScriptBlock
            $script:capturedAppxParameterList = $ParameterList
            [pscustomobject]@{ MockHandle = $true }
        }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedAppxScriptBlock -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedAppxParameterList -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name appxRemovalProcessRunningAtLaunch -Scope Script -ErrorAction SilentlyContinue
    }

    It "prompts and exits when no AppX packages are selected" {
        Invoke-WPFAppxRemoval

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "No AppX Package selected" -and
                $Title -eq "Error" -and
                $Button -eq "OK" -and
                $Icon -eq "Error"
        }
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 0 -Exactly
    }

    It "prevents overlapping AppX removal operations" {
        $script:sync.ProcessRunning = $true
        $script:sync.selectedAppx.Add("WPFAppxExample")

        Invoke-WPFAppxRemoval

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "An AppX process is currently running." -and
                $Title -eq "WinUtil" -and
                $Button -eq "OK" -and
                $Icon -eq "Warning"
        }
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 0 -Exactly
    }

    It "passes selected AppX keys and app metadata to the removal runspace" {
        $script:sync.selectedAppx.Add("WPFAppxExample")
        $script:sync.configs.appxHashtable["WPFAppxExample"] = [pscustomobject]@{
            Content = "Example App"
            PackageId = "Example.Package"
        }

        Invoke-WPFAppxRemoval
        $script:sync.selectedAppx.Add("WPFAppxChangedAfterLaunch")

        $script:appxRemovalProcessRunningAtLaunch | Should -BeTrue
        $script:capturedAppxParameterList[0][1] | Should -HaveCount 1
        Should -Invoke -CommandName Show-WinUtilMessage -Times 0 -Exactly
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock -is [scriptblock] -and
                $ParameterList.Count -eq 2 -and
                $ParameterList[0][0] -eq "selected" -and
                $ParameterList[0][1][0] -eq "WPFAppxExample" -and
                $ParameterList[1][0] -eq "apps" -and
                $ParameterList[1][1]["WPFAppxExample"].PackageId -eq "Example.Package"
        }
    }
}

Describe "Invoke-WPFAppxRemoval runspace body" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            ProcessRunning = $false
            Form = [pscustomobject]@{ Dispatcher = [pscustomobject]@{} }
            selectedAppx = [System.Collections.Generic.List[string]]::new()
            configs = @{
                appxHashtable = @{}
            }
        })
        $script:capturedAppxScriptBlock = $null
        $script:apps = @{
            WPFAppxExample = [pscustomobject]@{
                Content = "Example App"
                PackageId = "Example.Package"
            }
            WPFAppxMicrosoft_XboxGamingOverlay = [pscustomobject]@{
                Content = "Xbox Gaming Overlay"
                PackageId = "Microsoft.XboxGamingOverlay"
            }
            WPFAppxMicrosoft_WindowsNotepad = [pscustomobject]@{
                Content = "Notepad"
                PackageId = "Microsoft.WindowsNotepad"
            }
            WPFAppxMSTeams = [pscustomobject]@{
                Content = "Microsoft Teams"
                PackageId = "MSTeams"
            }
        }

        Mock Invoke-WPFRunspace {
            $script:capturedAppxScriptBlock = $ScriptBlock
            [pscustomobject]@{ MockHandle = $true }
        }
        Mock Show-WinUtilMessage { "OK" }
        Mock Write-Host { }
        Mock Write-WinUtilLog { }
        Mock Set-WinUtilTweaksProgressIndicator { }
        Mock Invoke-WPFUIThread { }
        Mock Stop-Process { }
        Mock Set-ItemProperty { }
        Mock Get-AppxPackage {
            [pscustomobject]@{
                Name = $Name
                PackageFullName = "$Name.FullName"
            }
        }
        Mock Remove-AppxPackage { }
        Mock Remove-WinUtilProvisionedAPPX { }
        Mock Get-Package {
            [pscustomobject]@{
                Name = "Microsoft Teams Meeting Add-in"
            }
        }
        Mock Uninstall-Package { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedAppxScriptBlock -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name apps -Scope Script -ErrorAction SilentlyContinue
    }

    It "removes selected AppX packages and clears ProcessRunning when finished" {
        $selected = @("WPFAppxExample")
        $script:sync.selectedAppx.Add("WPFAppxExample")
        $script:sync.configs.appxHashtable = $script:apps

        Invoke-WPFAppxRemoval
        & $script:capturedAppxScriptBlock -selected $selected -apps $script:apps

        Should -Invoke -CommandName Get-AppxPackage -Times 1 -Exactly -ParameterFilter {
            $Name -eq "*Example.Package*" -and $AllUsers -eq $true
        }
        Should -Invoke -CommandName Remove-AppxPackage -Times 1 -Exactly -ParameterFilter {
            $Package -eq "*Example.Package*.FullName"
        }
        Should -Invoke -CommandName Remove-WinUtilProvisionedAPPX -Times 1 -Exactly -ParameterFilter {
            $PackageList.Count -eq 1 -and $PackageList[0] -eq "Example.Package"
        }
        Should -Invoke -CommandName Set-WinUtilTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "Removing Example App (1/1)" -and $Percent -eq 0
        }
        Should -Invoke -CommandName Set-WinUtilTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "Removed Example App (1/1)" -and $Percent -eq 90
        }
        Should -Invoke -CommandName Set-WinUtilTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "AppX removal finished" -and $Percent -eq 100
        }
        Should -Invoke -CommandName Invoke-WPFUIThread -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.ToString() -like '*Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"*'
        }
        $script:sync.ProcessRunning | Should -BeFalse
    }

    It "shows failure feedback and clears ProcessRunning when removal fails" {
        $selected = @("WPFAppxExample")
        $script:sync.selectedAppx.Add("WPFAppxExample")
        $script:sync.configs.appxHashtable = $script:apps
        Mock Remove-WinUtilAPPX { throw "Removal failed" }

        Invoke-WPFAppxRemoval
        & $script:capturedAppxScriptBlock -selected $selected -apps $script:apps

        Should -Invoke -CommandName Set-WinUtilTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "AppX removal failed" -and $Percent -eq 100
        }
        Should -Invoke -CommandName Invoke-WPFUIThread -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.ToString() -like '*Set-WinUtilTaskbaritem -state "Error" -overlay "warning"*'
        }
        Should -Invoke -CommandName Remove-WinUtilProvisionedAPPX -Times 0 -Exactly
        $script:sync.ProcessRunning | Should -BeFalse
    }

    It "removes packages without UI progress during headless autorun" {
        $selected = @("WPFAppxExample")
        $script:sync.Remove("Form")
        $script:sync.selectedAppx.Add("WPFAppxExample")
        $script:sync.configs.appxHashtable = $script:apps

        Invoke-WPFAppxRemoval
        & $script:capturedAppxScriptBlock -selected $selected -apps $script:apps

        Should -Invoke -CommandName Remove-AppxPackage -Times 1 -Exactly
        Should -Invoke -CommandName Remove-WinUtilProvisionedAPPX -Times 1 -Exactly
        Should -Invoke -CommandName Set-WinUtilTweaksProgressIndicator -Times 0 -Exactly
        Should -Invoke -CommandName Invoke-WPFUIThread -Times 0 -Exactly
        $script:sync.ProcessRunning | Should -BeFalse
    }

    It "shows failure feedback when provisioned package removal fails" {
        $selected = @("WPFAppxExample")
        $script:sync.selectedAppx.Add("WPFAppxExample")
        $script:sync.configs.appxHashtable = $script:apps
        Mock Remove-WinUtilProvisionedAPPX { throw "Provisioned removal failed" }

        Invoke-WPFAppxRemoval
        & $script:capturedAppxScriptBlock -selected $selected -apps $script:apps

        Should -Invoke -CommandName Set-WinUtilTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "AppX removal failed" -and $Percent -eq 100
        }
        Should -Invoke -CommandName Set-WinUtilTweaksProgressIndicator -Times 0 -Exactly -ParameterFilter {
            $Label -eq "AppX removal finished"
        }
        Should -Invoke -CommandName Invoke-WPFUIThread -Times 1 -Exactly -ParameterFilter {
            $ScriptBlock.ToString() -like '*Set-WinUtilTaskbaritem -state "Error" -overlay "warning"*'
        }
        Should -Invoke -CommandName Invoke-WPFUIThread -Times 0 -Exactly -ParameterFilter {
            $ScriptBlock.ToString() -like '*Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"*'
        }
        $script:sync.ProcessRunning | Should -BeFalse
    }

    It "applies special cleanup for Xbox overlay, Notepad, and Teams selections" {
        $selected = @(
            "WPFAppxMicrosoft_XboxGamingOverlay",
            "WPFAppxMicrosoft_WindowsNotepad",
            "WPFAppxMSTeams"
        )
        foreach ($key in $selected) {
            $script:sync.selectedAppx.Add($key)
        }
        $script:sync.configs.appxHashtable = $script:apps

        Invoke-WPFAppxRemoval
        & $script:capturedAppxScriptBlock -selected $selected -apps $script:apps

        Should -Invoke -CommandName Stop-Process -Times 1 -Exactly -ParameterFilter {
            $Name -eq "GameBarFTServer" -and
                $Force -eq $true -and
                $Confirm -eq $false -and
                $ErrorAction -eq "SilentlyContinue"
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -and
                $Name -eq "AppCaptureEnabled" -and
                $Value -eq 0
        }
        Should -Invoke -CommandName Stop-Process -Times 1 -Exactly -ParameterFilter {
            $Name -eq "dllhost" -and
                $Force -eq $true -and
                $Confirm -eq $false -and
                $ErrorAction -eq "SilentlyContinue"
        }
        Should -Invoke -CommandName Get-Package -Times 1 -Exactly -ParameterFilter {
            $Name -eq "Microsoft Teams*"
        }
        Should -Invoke -CommandName Uninstall-Package -Times 1 -Exactly -ParameterFilter {
            $InputObject.Name -eq "Microsoft Teams Meeting Add-in" -and $Force -eq $true
        }
        Should -Invoke -CommandName Remove-AppxPackage -Times 3 -Exactly
        Should -Invoke -CommandName Remove-WinUtilProvisionedAPPX -Times 1 -Exactly -ParameterFilter {
            $PackageList.Count -eq 3 -and
            $PackageList[0] -eq "Microsoft.XboxGamingOverlay" -and
            $PackageList[1] -eq "Microsoft.WindowsNotepad" -and
            $PackageList[2] -eq "MSTeams"
        }
        $script:sync.ProcessRunning | Should -BeFalse
    }
}
