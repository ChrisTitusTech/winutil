#===========================================================================
# Tests - Tweak Orchestration
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Measure-WinUtilStep.ps1")
    . (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilTweaks.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFtweaksbutton.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFundoall.ps1")

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
        param([scriptblock]$ScriptBlock, [hashtable]$Parameters, [switch]$Async)
    }
    function Write-WinUtilLog {
        param($Message, $Level, $Component)
    }
    function Start-WinUtilJob {
        param([string]$Name, [scriptblock]$ScriptBlock, [hashtable]$Parameters, [string]$Description, [switch]$DisableAppList)
    }
    function Step-WinUtilJob {
        param([string]$Status, [int]$Percent, [string]$State, [string]$Overlay, [switch]$Hide)
    }
    function Show-WinUtilMessage {
        param($Message, $Title, $Button, $Icon)
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
            ActiveJob = $null
            selectedTweaks = [System.Collections.Generic.List[string]]::new()
            WPFchangedns = [pscustomobject]@{
                text = "Cloudflare"
            }
        })
        $script:capturedTweaksJob = $null

        Mock Invoke-WinUtilTweaks { }
        # the real one returns $true on success, and the workflow now stops when it does not
        Mock Set-WinUtilDNS { return $true }
        Mock Invoke-WPFUIThread { }
        Mock Write-WinUtilLog { }
        Mock Step-WinUtilJob { }
        Mock Show-WinUtilMessage { "OK" }
        Mock Write-Host { }
        Mock Start-WinUtilJob {
            $script:capturedTweaksJob = [pscustomobject]@{
                ScriptBlock = $ScriptBlock
                Parameters = $Parameters
            }
        }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedTweaksJob -Scope Script -ErrorAction SilentlyContinue
    }

    It "prompts and exits when nothing is selected and DNS is left at the default" {
        $script:sync.WPFchangedns.text = "Default"

        Invoke-WPFtweaksbutton

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "Please check the tweaks you wish to perform."
        }
        Should -Invoke -CommandName Start-WinUtilJob -Times 0 -Exactly
    }

    It "queues a tweak job with the selection and DNS provider" {
        $script:sync.selectedTweaks.Add("WPFTweaksTelemetry")
        $script:sync.selectedTweaks.Add("WPFTweaksServices")

        Invoke-WPFtweaksbutton

        Should -Invoke -CommandName Start-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Name -eq "Tweaks" -and $ScriptBlock -is [scriptblock]
        }
        $script:capturedTweaksJob.Parameters.Tweaks | Should -HaveCount 2
        $script:capturedTweaksJob.Parameters.Tweaks[0] | Should -Be "WPFTweaksTelemetry"
        $script:capturedTweaksJob.Parameters.DnsProvider | Should -Be "Cloudflare"
    }

    It "applies every selected tweak and the DNS provider inside the job body" {
        $script:sync.selectedTweaks.Add("WPFTweaksTelemetry")
        $script:sync.selectedTweaks.Add("WPFTweaksServices")

        Invoke-WPFtweaksbutton
        $jobParameters = $script:capturedTweaksJob.Parameters
        & $script:capturedTweaksJob.ScriptBlock @jobParameters

        Should -Invoke -CommandName Set-WinUtilDNS -Times 1 -Exactly -ParameterFilter {
            $DNSProvider -eq "Cloudflare"
        }
        Should -Invoke -CommandName Invoke-WinUtilTweaks -Times 2 -Exactly
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Applying WPFTweaksTelemetry (1/2)" -and $Percent -eq 0
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Applying WPFTweaksServices (2/2)" -and $Percent -eq 50
        }
    }

    It "stops the run when the DNS change fails" {
        # carrying on would leave the machine half configured, so the job ends and reports it
        $script:sync.selectedTweaks.Add("WPFTweaksTelemetry")
        Mock Set-WinUtilDNS { return $false }

        Invoke-WPFtweaksbutton
        $jobParameters = $script:capturedTweaksJob.Parameters

        { & $script:capturedTweaksJob.ScriptBlock @jobParameters } | Should -Throw -ExpectedMessage "*DNS change to Cloudflare failed*"
        Should -Invoke -CommandName Invoke-WinUtilTweaks -Times 0 -Exactly
    }

    It "carries on when the DNS change succeeds" {
        $script:sync.selectedTweaks.Add("WPFTweaksTelemetry")
        Mock Set-WinUtilDNS { return $true }

        Invoke-WPFtweaksbutton
        $jobParameters = $script:capturedTweaksJob.Parameters
        & $script:capturedTweaksJob.ScriptBlock @jobParameters

        Should -Invoke -CommandName Invoke-WinUtilTweaks -Times 1 -Exactly
    }

    It "takes the restore point before any other tweak runs" {
        $script:sync.selectedTweaks.Add("WPFTweaksRestorePoint")
        $script:sync.selectedTweaks.Add("WPFTweaksTelemetry")
        $script:appliedOrder = [System.Collections.Generic.List[string]]::new()
        Mock Invoke-WinUtilTweaks { $script:appliedOrder.Add($CheckBox) }

        Invoke-WPFtweaksbutton
        $jobParameters = $script:capturedTweaksJob.Parameters
        & $script:capturedTweaksJob.ScriptBlock @jobParameters

        $script:appliedOrder | Should -Be @("WPFTweaksRestorePoint", "WPFTweaksTelemetry")
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Creating restore point" -and $Percent -eq 0
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Applying WPFTweaksTelemetry (2/2)" -and $Percent -eq 50
        }
    }
}

Describe "Invoke-WPFundoall" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            ActiveJob = $null
            selectedTweaks = [System.Collections.Generic.List[string]]::new()
        })
        $script:capturedUndoJob = $null

        Mock Invoke-WinUtilTweaks { }
        Mock Write-WinUtilLog { }
        Mock Step-WinUtilJob { }
        Mock Show-WinUtilMessage { "OK" }
        Mock Write-Host { }
        Mock Start-WinUtilJob {
            $script:capturedUndoJob = [pscustomobject]@{
                ScriptBlock = $ScriptBlock
                Parameters = $Parameters
            }
        }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedUndoJob -Scope Script -ErrorAction SilentlyContinue
    }

    It "prompts and exits when nothing is selected" {
        Invoke-WPFundoall

        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "Please check the tweaks you wish to undo."
        }
        Should -Invoke -CommandName Start-WinUtilJob -Times 0 -Exactly
    }

    It "undoes every selected tweak inside the job body" {
        $script:sync.selectedTweaks.Add("WPFTweaksTelemetry")
        $script:sync.selectedTweaks.Add("WPFTweaksServices")

        Invoke-WPFundoall

        Should -Invoke -CommandName Start-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Name -eq "Undo tweaks"
        }
        $jobParameters = $script:capturedUndoJob.Parameters
        & $script:capturedUndoJob.ScriptBlock @jobParameters

        Should -Invoke -CommandName Invoke-WinUtilTweaks -Times 2 -Exactly -ParameterFilter { $undo -eq $true }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Undoing WPFTweaksTelemetry (1/2)" -and $Percent -eq 0
        }
        Should -Invoke -CommandName Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Undoing WPFTweaksServices (2/2)" -and $Percent -eq 50
        }
    }
}
