#===========================================================================
# Tests - AppX Management
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilInstalledAPPX.ps1")
    . (Join-Path $script:repoRoot "functions\private\Install-WinUtilAPPX.ps1")
    . (Join-Path $script:repoRoot "functions\private\Complete-WinUtilPackageRun.ps1")
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
    function Start-WinUtilJob {
        param([string]$Name, [scriptblock]$ScriptBlock, [hashtable]$Parameters, [string]$Description, [switch]$DisableAppList)
    }
    function Step-WinUtilJob {
        param([string]$Status, [int]$Percent, [string]$State, [string]$Overlay)
    }
    function Show-WinUtilMessage {
        param($Message, $Title, $Button, $Icon)
    }
    function Invoke-WPFRunspace {
        param($ArgumentList, $ParameterList, [scriptblock]$ScriptBlock)
    }
    function Invoke-WPFUIThread {
        param([scriptblock]$ScriptBlock, [hashtable]$Parameters, [switch]$Async)
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
        $result = Install-WinUtilAPPX -Name "Example.Package" -StoreId "9EXAMPLE1234"

        $result.Outcome | Should -Be "Succeeded"
        $result.Manager | Should -Be "appx"
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

    It "does not return WinGet bootstrap output as a package result" {
        Mock powershell.exe { $global:LASTEXITCODE = 0 }
        Mock Install-WinUtilWinget { [pscustomobject]@{ Provider = "NuGet" } }
        Mock Install-WinUtilProgramWinget {
            [pscustomobject]@{ Package = "msstore:9EXAMPLE1234"; Outcome = "Skipped" }
        }

        $result = @(Install-WinUtilAPPX -Name "Example.Package" -StoreId "9EXAMPLE1234")

        $result.Count | Should -Be 1
        $result[0].Package | Should -Be "msstore:9EXAMPLE1234"
        $result[0].Outcome | Should -Be "Skipped"
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
            ActiveJob = $null
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

        Mock Get-WinUtilInstalledAPPX { @("Example.Package") }
        Mock Invoke-WPFAppxInstall { }
        Mock Step-WinUtilJob { }
        Mock Invoke-WPFUIThread { $uiParameters = $Parameters; & $ScriptBlock @uiParameters }
        Mock Start-WinUtilJob {
            $jobParameters = $Parameters
            & $ScriptBlock @jobParameters
        }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    It "selects configured packages returned by the compatibility-safe query" {
        Invoke-WPFButton -Button "WPFGetInstalledAppx"

        Should -Invoke -CommandName Start-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Name -eq "GetInstalledAppx"
        }
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
        $source | Should -Match '(?s)AppX provisioned package removal failed:.*WinUtilErrorReported.*throw \$exception.*AppX provisioned package removal completed\.'
    }
}

Describe "Invoke-WPFAppxInstall" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            ActiveJob = $null
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

        Mock Show-WinUtilMessage { "OK" }
        Mock Write-Host { }
        Mock Write-WinUtilLog { }
        Mock Invoke-WPFUIThread { }
        Mock Install-WinUtilAPPX { }
        Mock Complete-WinUtilPackageRun { }
        Mock Step-WinUtilJob { }
        Mock Start-WinUtilJob {
            $script:capturedAppxInstallScriptBlock = $ScriptBlock
            $script:capturedAppxInstallParameters = $Parameters
        }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedAppxInstallScriptBlock -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedAppxInstallParameterList -Scope Script -ErrorAction SilentlyContinue
    }

    It "prompts and exits when no AppX packages are selected for install" {
        Invoke-WPFAppxInstall

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "No AppX Package selected" -and
                $Title -eq "Error" -and
                $Button -eq "OK" -and
                $Icon -eq "Error"
        }
        Should -Invoke -CommandName Start-WinUtilJob -Times 0 -Exactly
    }

    It "queues an install job for the selected AppX packages" {
        $script:sync.selectedAppx.Add("WPFAppxExample")

        Invoke-WPFAppxInstall

        Should -Invoke -CommandName Start-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Name -eq "AppX install"
        }
        $script:capturedAppxInstallParameters.Selected[0] | Should -Be "WPFAppxExample"
    }

    It "installs selected AppX packages with their Store IDs" {
        $script:sync.selectedAppx.Add("WPFAppxExample")

        Invoke-WPFAppxInstall
        $jobParameters = $script:capturedAppxInstallParameters
        & $script:capturedAppxInstallScriptBlock @jobParameters

        Should -Invoke -CommandName Install-WinUtilAPPX -Times 1 -Exactly -ParameterFilter {
            $Name -eq "Example.Package" -and $StoreId -eq "9EXAMPLE1234"
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Installing Example App (1/1)" -and $Percent -eq 0
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Installed Example App (1/1)" -and $Percent -eq 100
        }
    }

    It "lets an install failure surface so the job layer can handle it" {
        $script:sync.selectedAppx.Add("WPFAppxExample")
        Mock Install-WinUtilAPPX { throw "Install failed" }

        Invoke-WPFAppxInstall
        $jobParameters = $script:capturedAppxInstallParameters

        { & $script:capturedAppxInstallScriptBlock @jobParameters } | Should -Throw "Install failed"
    }

    It "passes a skipped Store result to package completion and reports it as skipped" {
        $script:sync.selectedAppx.Add("WPFAppxExample")
        Mock Install-WinUtilAPPX {
            [pscustomobject]@{
                Package = "9EXAMPLE1234"
                Manager = "winget"
                Action = "Install"
                ExitCode = -1978335107
                Outcome = "Skipped"
                Detail = "elevated context"
            }
        }

        Invoke-WPFAppxInstall
        $jobParameters = $script:capturedAppxInstallParameters
        & $script:capturedAppxInstallScriptBlock @jobParameters

        Should -Invoke Complete-WinUtilPackageRun -Times 1 -Exactly -ParameterFilter {
            $Action -eq "Install" -and $Results.Count -eq 1 -and $Results[0].Outcome -eq "Skipped"
        }
        Should -Invoke Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Skipped Example App (1/1)" -and $Percent -eq 100
        }
    }

}
Describe "Invoke-WPFAppxRemoval" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            ActiveJob = $null
            Form = [pscustomobject]@{ Dispatcher = [pscustomobject]@{} }
            selectedAppx = [System.Collections.Generic.List[string]]::new()
            configs = @{
                appxHashtable = @{}
            }
        })
        $script:capturedAppxRemovalScriptBlock = $null
        $script:capturedAppxRemovalParameters = $null
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

        Mock Show-WinUtilMessage { "OK" }
        Mock Write-Host { }
        Mock Write-WinUtilLog { }
        Mock Step-WinUtilJob { }
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
        Mock Start-WinUtilJob {
            $script:capturedAppxRemovalScriptBlock = $ScriptBlock
            $script:capturedAppxRemovalParameters = $Parameters
        }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedAppxRemovalScriptBlock -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedAppxRemovalParameters -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name apps -Scope Script -ErrorAction SilentlyContinue
    }

    It "prompts and exits when no AppX packages are selected" {
        Invoke-WPFAppxRemoval

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "No AppX Package selected" -and
                $Title -eq "Error" -and
                $Button -eq "OK" -and
                $Icon -eq "Error"
        }
        Should -Invoke -CommandName Start-WinUtilJob -Times 0 -Exactly
    }

    It "queues a removal job with a snapshot of the selection and app metadata" {
        $script:sync.selectedAppx.Add("WPFAppxExample")
        $script:sync.configs.appxHashtable = $script:apps

        Invoke-WPFAppxRemoval
        $script:sync.selectedAppx.Add("WPFAppxChangedAfterLaunch")

        Should -Invoke -CommandName Start-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Name -eq "AppX" -and $ScriptBlock -is [scriptblock]
        }
        Should -Invoke -CommandName Show-WinUtilMessage -Times 0 -Exactly
        $script:capturedAppxRemovalParameters.Selected | Should -HaveCount 1
        $script:capturedAppxRemovalParameters.Selected[0] | Should -Be "WPFAppxExample"
        $script:capturedAppxRemovalParameters.Apps["WPFAppxExample"].PackageId | Should -Be "Example.Package"
    }

    It "removes the selected packages and reports progress for each one" {
        $script:sync.selectedAppx.Add("WPFAppxExample")
        $script:sync.configs.appxHashtable = $script:apps

        Invoke-WPFAppxRemoval
        $jobParameters = $script:capturedAppxRemovalParameters
        & $script:capturedAppxRemovalScriptBlock @jobParameters

        Should -Invoke -CommandName Get-AppxPackage -Times 1 -Exactly -ParameterFilter {
            $Name -eq "*Example.Package*" -and $AllUsers -eq $true
        }
        Should -Invoke -CommandName Remove-AppxPackage -Times 1 -Exactly -ParameterFilter {
            $Package -eq "*Example.Package*.FullName"
        }
        Should -Invoke -CommandName Remove-WinUtilProvisionedAPPX -Times 1 -Exactly -ParameterFilter {
            $PackageList.Count -eq 1 -and $PackageList[0] -eq "Example.Package"
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Removing Example App (1/1)" -and $Percent -eq 0
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Removed Example App (1/1)" -and $Percent -eq 90
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Removing provisioned AppX packages" -and $Percent -eq 90
        }
    }

    It "lets a removal failure surface so the job layer can handle it" {
        $script:sync.selectedAppx.Add("WPFAppxExample")
        $script:sync.configs.appxHashtable = $script:apps
        Mock Remove-WinUtilAPPX { throw "Removal failed" }

        Invoke-WPFAppxRemoval
        $jobParameters = $script:capturedAppxRemovalParameters

        { & $script:capturedAppxRemovalScriptBlock @jobParameters } | Should -Throw "Removal failed"
        Should -Invoke -CommandName Remove-WinUtilProvisionedAPPX -Times 0 -Exactly
    }

    It "lets a provisioned removal failure surface so the job layer can handle it" {
        $script:sync.selectedAppx.Add("WPFAppxExample")
        $script:sync.configs.appxHashtable = $script:apps
        Mock Remove-WinUtilProvisionedAPPX { throw "Provisioned removal failed" }

        Invoke-WPFAppxRemoval
        $jobParameters = $script:capturedAppxRemovalParameters

        { & $script:capturedAppxRemovalScriptBlock @jobParameters } | Should -Throw "Provisioned removal failed"
    }

    It "applies special cleanup for Xbox overlay, Notepad, and Teams selections" {
        foreach ($key in @("WPFAppxMicrosoft_XboxGamingOverlay", "WPFAppxMicrosoft_WindowsNotepad", "WPFAppxMSTeams")) {
            $script:sync.selectedAppx.Add($key)
        }
        $script:sync.configs.appxHashtable = $script:apps

        Invoke-WPFAppxRemoval
        $jobParameters = $script:capturedAppxRemovalParameters
        & $script:capturedAppxRemovalScriptBlock @jobParameters

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
    }
}
