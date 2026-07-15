#===========================================================================
# Tests - Tweak Orchestration
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilTweaks.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFtweaksbutton.ps1")

    function Set-WinUtilService {
        param($Name, $StartupType)
    }
    function Set-WinUtilRegistry {
        param($Name, $Path, $Type, $Value)
    }
    function Invoke-WinUtilScript {
        param($Name, [scriptblock]$ScriptBlock)
    }
    function Remove-WinUtilAPPX {
        param($Name)
    }
    function Remove-WinUtilProvisionedAPPX {
        param($PackageList)
    }
    function Set-WinUtilDNS {
        param($DNSProvider)
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
    function Write-WinUtilLog {
        param($Message, $Level, $Component)
    }

    function script:New-WinUtilTweaksConfig {
        [pscustomobject]@{
            WPFTweaksExample = [pscustomobject]@{
                service = @(
                    [pscustomobject]@{
                        Name = "DiagTrack"
                        StartupType = "Disabled"
                        OriginalType = "Automatic"
                    }
                )
                registry = @(
                    [pscustomobject]@{
                        Path = "HKLM:\Software\WinUtilTest"
                        Name = "AllowTelemetry"
                        Type = "DWord"
                        Value = "0"
                        OriginalValue = "1"
                    }
                )
                InvokeScript = @("Write-Output 'apply tweak'")
                UndoScript = @("Write-Output 'undo tweak'")
                appx = @("Microsoft.ExampleApp")
            }
            WPFTweaksServiceOnly = [pscustomobject]@{
                service = @(
                    [pscustomobject]@{
                        Name = "DiagTrack"
                        StartupType = "Disabled"
                        OriginalType = "Automatic"
                    }
                )
            }
        }
    }
}

Describe "Invoke-WinUtilTweaks" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            configs = @{
                tweaks = New-WinUtilTweaksConfig
            }
        })

        Mock Get-Service {
            [pscustomobject]@{
                Name = "DiagTrack"
                StartType = "Automatic"
            }
        }
        Mock Set-WinUtilService { }
        Mock Set-WinUtilRegistry { }
        Mock Invoke-WinUtilScript { }
        Mock Remove-WinUtilAPPX { }
        Mock Remove-WinUtilProvisionedAPPX { }
        Mock Write-WinUtilLog { }
        Mock Write-Warning { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    It "dispatches apply actions to service, registry, script, and AppX helpers" {
        Invoke-WinUtilTweaks -CheckBox "WPFTweaksExample"

        Should -Invoke -CommandName Get-Service -Times 1 -Exactly -ParameterFilter {
            $Name -eq "DiagTrack" -and $ErrorAction -eq "Stop"
        }
        Should -Invoke -CommandName Set-WinUtilService -Times 1 -Exactly -ParameterFilter {
            $Name -eq "DiagTrack" -and $StartupType -eq "Disabled"
        }
        Should -Invoke -CommandName Set-WinUtilRegistry -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\Software\WinUtilTest" -and
                $Name -eq "AllowTelemetry" -and
                $Type -eq "DWord" -and
                $Value -eq "0"
        }
        Should -Invoke -CommandName Invoke-WinUtilScript -Times 1 -Exactly -ParameterFilter {
            $Name -eq "WPFTweaksExample" -and $ScriptBlock.ToString() -eq "Write-Output 'apply tweak'"
        }
        Should -Invoke -CommandName Remove-WinUtilAPPX -Times 1 -Exactly -ParameterFilter {
            $Name -eq "Microsoft.ExampleApp"
        }
        Should -Invoke -CommandName Remove-WinUtilProvisionedAPPX -Times 1 -Exactly -ParameterFilter {
            $PackageList.Count -eq 1 -and $PackageList[0] -eq "Microsoft.ExampleApp"
        }
    }

    It "uses original registry values and service startup types in undo mode" {
        Invoke-WinUtilTweaks -CheckBox "WPFTweaksExample" -undo $true

        Should -Invoke -CommandName Get-Service -Times 0 -Exactly
        Should -Invoke -CommandName Set-WinUtilService -Times 1 -Exactly -ParameterFilter {
            $Name -eq "DiagTrack" -and $StartupType -eq "Automatic"
        }
        Should -Invoke -CommandName Set-WinUtilRegistry -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\Software\WinUtilTest" -and
                $Name -eq "AllowTelemetry" -and
                $Type -eq "DWord" -and
                $Value -eq "1"
        }
        Should -Invoke -CommandName Invoke-WinUtilScript -Times 1 -Exactly -ParameterFilter {
            $Name -eq "WPFTweaksExample" -and $ScriptBlock.ToString() -eq "Write-Output 'undo tweak'"
        }
        Should -Invoke -CommandName Remove-WinUtilAPPX -Times 0 -Exactly
        Should -Invoke -CommandName Remove-WinUtilProvisionedAPPX -Times 0 -Exactly
    }

    It "keeps a user-changed service startup type by default" {
        Mock Get-Service {
            [pscustomobject]@{
                Name = "DiagTrack"
                StartType = "Manual"
            }
        } -ParameterFilter { $Name -eq "DiagTrack" }

        Invoke-WinUtilTweaks -CheckBox "WPFTweaksServiceOnly"

        Should -Invoke -CommandName Get-Service -Times 1 -Exactly
        Should -Invoke -CommandName Set-WinUtilService -Times 0 -Exactly
    }

    It "forces a service startup type when KeepServiceStartup is disabled" {
        Invoke-WinUtilTweaks -CheckBox "WPFTweaksServiceOnly" -KeepServiceStartup $false

        Should -Invoke -CommandName Get-Service -Times 0 -Exactly
        Should -Invoke -CommandName Set-WinUtilService -Times 1 -Exactly -ParameterFilter {
            $Name -eq "DiagTrack" -and $StartupType -eq "Disabled"
        }
    }
}

Describe "Invoke-WPFtweaksbutton" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            ProcessRunning = $false
            selectedTweaks = [System.Collections.Generic.List[string]]::new()
            WPFchangedns = [pscustomobject]@{
                text = "Cloudflare"
            }
        })

        Mock Invoke-WPFRunspace { [pscustomobject]@{ MockHandle = $true } }
        Mock Invoke-WinUtilTweaks { }
        Mock Invoke-WPFUIThread { }
        Mock Set-WinUtilProgressBar { }
        Mock Write-WinUtilLog { }
        Mock Write-Host { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    It "passes selected tweaks, DNS provider, and progress counters to the tweak runspace" {
        $script:sync.selectedTweaks.Add("WPFTweaksTelemetry")
        $script:sync.selectedTweaks.Add("WPFTweaksServices")

        Invoke-WPFtweaksbutton

        Should -Invoke -CommandName Invoke-WPFRunspace -Times 1 -Exactly -ParameterFilter {
            $ParameterList.Count -eq 4 -and
                $ParameterList[0][0] -eq "tweaks" -and
                $ParameterList[0][1].Count -eq 2 -and
                $ParameterList[0][1][0] -eq "WPFTweaksTelemetry" -and
                $ParameterList[0][1][1] -eq "WPFTweaksServices" -and
                $ParameterList[1][0] -eq "dnsProvider" -and
                $ParameterList[1][1] -eq "Cloudflare" -and
                $ParameterList[2][0] -eq "completedSteps" -and
                $ParameterList[2][1] -eq 0 -and
                $ParameterList[3][0] -eq "totalSteps" -and
                $ParameterList[3][1] -eq 2
        }
    }

    It "runs the restore point first and advances progress before queueing remaining tweaks" {
        $script:sync.selectedTweaks.Add("WPFTweaksRestorePoint")
        $script:sync.selectedTweaks.Add("WPFTweaksTelemetry")

        Invoke-WPFtweaksbutton

        Should -Invoke -CommandName Invoke-WinUtilTweaks -Times 1 -Exactly -ParameterFilter {
            $CheckBox -eq "WPFTweaksRestorePoint"
        }
        Should -Invoke -CommandName Invoke-WPFRunspace -Times 1 -Exactly -ParameterFilter {
            $ParameterList.Count -eq 4 -and
                $ParameterList[0][0] -eq "tweaks" -and
                $ParameterList[0][1].Count -eq 1 -and
                $ParameterList[0][1][0] -eq "WPFTweaksTelemetry" -and
                $ParameterList[1][0] -eq "dnsProvider" -and
                $ParameterList[1][1] -eq "Cloudflare" -and
                $ParameterList[2][0] -eq "completedSteps" -and
                $ParameterList[2][1] -eq 1 -and
                $ParameterList[3][0] -eq "totalSteps" -and
                $ParameterList[3][1] -eq 2
        }
    }
}
