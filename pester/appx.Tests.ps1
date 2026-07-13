#===========================================================================
# Tests - AppX Removal
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Remove-WinUtilAPPX.ps1")
    . (Join-Path $script:repoRoot "functions\private\Remove-WinUtilProvisionedAPPX.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFAppxRemoval.ps1")

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

    function Write-WinUtilLog {
        param($Message, $Level, $Component)
    }
    function Show-WinUtilMessage {
        param($Message, $Title, $Button, $Icon)
    }
    function Invoke-WPFRunspace {
        param($ArgumentList, $ParameterList, [scriptblock]$ScriptBlock)
    }
    function Get-AppxPackage {
        param($Name, [switch]$AllUsers)
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

    It "handles child process failures before logging completion" {
        $source = Get-Content -Path $provisionedSourcePath -Raw

        $source | Should -Match '\$removalOutput = powershell\.exe .* 2>&1'
        $source | Should -Match 'if \(\$LASTEXITCODE -ne 0 -or \$null -ne \$removalOutput\)'
        $source | Should -Match 'Write-WinUtilLog -Level "ERROR" -Component "AppX" -Message "AppX provisioned package removal failed:'
        $source | Should -Match '(?s)AppX provisioned package removal failed:.*return.*AppX provisioned package removal completed\.'
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

        Mock Show-WinUtilMessage { "OK" }
        Mock Invoke-WPFRunspace {
            $script:capturedAppxScriptBlock = $ScriptBlock
            $script:capturedAppxParameterList = $ParameterList
            [pscustomobject]@{ MockHandle = $true }
        }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedAppxScriptBlock -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedAppxParameterList -Scope Script -ErrorAction SilentlyContinue
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

    It "passes selected AppX keys and app metadata to the removal runspace" {
        $script:sync.selectedAppx.Add("WPFAppxExample")
        $script:sync.configs.appxHashtable["WPFAppxExample"] = [pscustomobject]@{
            Content = "Example App"
            PackageId = "Example.Package"
        }

        Invoke-WPFAppxRemoval

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
