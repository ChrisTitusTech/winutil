#===========================================================================
# Tests - AppX Removal
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Remove-WinUtilAPPX.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFAppxRemoval.ps1")

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
            [switch]$AllUsers
        )
        process { }
    }
    function Get-AppxProvisionedPackage {
        param([switch]$Online)
    }
    function Remove-AppxProvisionedPackage {
        param(
            [Parameter(ValueFromPipeline = $true)]
            $InputObject,
            [switch]$Online
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
            [pscustomobject]@{
                Name = $Name
            }
        }
        Mock Remove-AppxPackage { }
        Mock Get-AppxProvisionedPackage {
            @(
                [pscustomobject]@{ DisplayName = "Microsoft.XboxGamingOverlay" }
                [pscustomobject]@{ DisplayName = "Microsoft.WindowsCalculator" }
            )
        }
        Mock Remove-AppxProvisionedPackage { }
    }

    It "removes matching installed and provisioned AppX packages" {
        Remove-WinUtilAPPX -Name "Microsoft.Xbox*"

        Should -Invoke -CommandName Get-AppxPackage -Times 1 -Exactly -ParameterFilter {
            $Name -eq "Microsoft.Xbox*" -and $AllUsers -eq $true
        }
        Should -Invoke -CommandName Remove-AppxPackage -Times 1 -Exactly -ParameterFilter {
            $InputObject.Name -eq "Microsoft.Xbox*" -and $AllUsers -eq $true
        }
        Should -Invoke -CommandName Get-AppxProvisionedPackage -Times 1 -Exactly -ParameterFilter {
            $Online -eq $true
        }
        Should -Invoke -CommandName Remove-AppxProvisionedPackage -Times 1 -Exactly -ParameterFilter {
            $InputObject.DisplayName -eq "Microsoft.XboxGamingOverlay" -and $Online -eq $true
        }
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
            }
        }
        Mock Remove-AppxPackage { }
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
            $Name -eq "Example.Package" -and $AllUsers -eq $true
        }
        Should -Invoke -CommandName Remove-AppxPackage -Times 1 -Exactly -ParameterFilter {
            $InputObject.Name -eq "Example.Package" -and $AllUsers -eq $true
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
            $Name -eq "GameBarFTServer"
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -and
                $Name -eq "AppCaptureEnabled" -and
                $Value -eq 0
        }
        Should -Invoke -CommandName Stop-Process -Times 1 -Exactly -ParameterFilter {
            $Name -eq "dllhost"
        }
        Should -Invoke -CommandName Get-Package -Times 1 -Exactly -ParameterFilter {
            $Name -eq "Microsoft Teams*"
        }
        Should -Invoke -CommandName Uninstall-Package -Times 1 -Exactly -ParameterFilter {
            $InputObject.Name -eq "Microsoft Teams Meeting Add-in" -and $Force -eq $true
        }
        Should -Invoke -CommandName Remove-AppxPackage -Times 3 -Exactly
        $script:sync.ProcessRunning | Should -BeFalse
    }
}
