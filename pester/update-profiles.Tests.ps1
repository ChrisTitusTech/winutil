#===========================================================================
# Tests - Windows Update Profiles
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFUpdatesdisable.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFUpdatesdefault.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFUpdatessecurity.ps1")

    function Write-WinUtilLog {
        param($Message, $Level, $Component)
    }
    function Get-ScheduledTask {
        param($TaskPath)
    }
    function Disable-ScheduledTask {
        param(
            [Parameter(ValueFromPipeline = $true)]
            $InputObject,
            $ErrorAction
        )
        process { }
    }
    function Enable-ScheduledTask {
        param(
            [Parameter(ValueFromPipeline = $true)]
            $InputObject,
            $ErrorAction
        )
        process { }
    }
    function secedit {
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            $Arguments
        )
    }

    $script:updateTaskPaths = @(
        '\Microsoft\Windows\InstallService\*',
        '\Microsoft\Windows\UpdateOrchestrator\*',
        '\Microsoft\Windows\UpdateAssistant\*',
        '\Microsoft\Windows\WaaSMedic\*',
        '\Microsoft\Windows\WindowsUpdate\*',
        '\Microsoft\WindowsUpdate\*'
    )
}

Describe "Invoke-WPFUpdatesdisable" {
    BeforeEach {
        Mock Write-Host { }
        Mock Write-WinUtilLog { }
        Mock New-Item { }
        Mock Set-ItemProperty { }
        Mock Set-Service { }
        Mock Stop-Service { }
        Mock Remove-Item { }
        Mock Get-ScheduledTask {
            [pscustomobject]@{
                TaskPath = $TaskPath
            }
        }
        Mock Disable-ScheduledTask { }
    }

    It "sets update disable registry policy values" {
        Invoke-WPFUpdatesdisable

        Should -Invoke -CommandName New-Item -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -and $Force -eq $true
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -and
                $Name -eq "NoAutoUpdate" -and
                $Type -eq "DWord" -and
                $Value -eq 1
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -and
                $Name -eq "AUOptions" -and
                $Type -eq "DWord" -and
                $Value -eq 1
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -and
                $Name -eq "DODownloadMode" -and
                $Type -eq "DWord" -and
                $Value -eq 0
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -and
                $Name -eq "SettingsPageVisibility" -and
                $Value -eq "hide:windowsupdate"
        }
    }

    It "disables update services and clears the SoftwareDistribution folder" {
        Invoke-WPFUpdatesdisable

        Should -Invoke -CommandName Set-Service -Times 1 -Exactly -ParameterFilter {
            $Name -eq "BITS" -and $StartupType -eq "Disabled"
        }
        Should -Invoke -CommandName Set-Service -Times 1 -Exactly -ParameterFilter {
            $Name -eq "wuauserv" -and $StartupType -eq "Disabled"
        }
        Should -Invoke -CommandName Stop-Service -Times 1 -Exactly -ParameterFilter {
            $Name -eq "UsoSvc" -and $Force -eq $true
        }
        Should -Invoke -CommandName Set-Service -Times 1 -Exactly -ParameterFilter {
            $Name -eq "UsoSvc" -and $StartupType -eq "Disabled"
        }
        Should -Invoke -CommandName Remove-Item -Times 1 -Exactly -ParameterFilter {
            $Path -eq "C:\Windows\SoftwareDistribution\*" -and
                $Recurse -eq $true -and
                $Force -eq $true
        }
    }

    It "disables update scheduled task paths" {
        Invoke-WPFUpdatesdisable

        foreach ($expectedTaskPath in $script:updateTaskPaths) {
            $expected = $expectedTaskPath
            Should -Invoke -CommandName Get-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                $TaskPath -eq $expected
            }
        }
        Should -Invoke -CommandName Disable-ScheduledTask -Times $script:updateTaskPaths.Count -Exactly
    }
}

Describe "Invoke-WPFUpdatesdefault" {
    BeforeEach {
        Mock Write-Host { }
        Mock Write-WinUtilLog { }
        Mock Remove-Item { }
        Mock Remove-ItemProperty { }
        Mock Set-Service { }
        Mock Start-Service { }
        Mock Get-ScheduledTask {
            [pscustomobject]@{
                TaskPath = $TaskPath
            }
        }
        Mock Enable-ScheduledTask { }
        Mock secedit { }
    }

    It "removes update policy registry paths and shows the Windows Update settings page" {
        Invoke-WPFUpdatesdefault

        $expectedPaths = @(
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization",
            "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        )

        foreach ($expectedRegistryPath in $expectedPaths) {
            $expected = $expectedRegistryPath
            Should -Invoke -CommandName Remove-Item -Times 1 -Exactly -ParameterFilter {
                $Path -eq $expected -and $Recurse -eq $true -and $Force -eq $true
            }
        }
        Should -Invoke -CommandName Remove-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -and
                $Name -eq "SettingsPageVisibility"
        }
    }

    It "restores update service startup types" {
        Invoke-WPFUpdatesdefault

        Should -Invoke -CommandName Set-Service -Times 1 -Exactly -ParameterFilter {
            $Name -eq "BITS" -and $StartupType -eq "Manual"
        }
        Should -Invoke -CommandName Set-Service -Times 1 -Exactly -ParameterFilter {
            $Name -eq "wuauserv" -and $StartupType -eq "Manual"
        }
        Should -Invoke -CommandName Start-Service -Times 1 -Exactly -ParameterFilter {
            $Name -eq "UsoSvc"
        }
        Should -Invoke -CommandName Set-Service -Times 1 -Exactly -ParameterFilter {
            $Name -eq "UsoSvc" -and $StartupType -eq "Automatic"
        }
        Should -Invoke -CommandName Set-Service -Times 1 -Exactly -ParameterFilter {
            $Name -eq "WaaSMedicSvc" -and $StartupType -eq "Manual"
        }
    }

    It "enables update scheduled task paths and resets local policy defaults" {
        Invoke-WPFUpdatesdefault

        foreach ($expectedTaskPath in $script:updateTaskPaths) {
            $expected = $expectedTaskPath
            Should -Invoke -CommandName Get-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                $TaskPath -eq $expected
            }
        }
        Should -Invoke -CommandName Enable-ScheduledTask -Times $script:updateTaskPaths.Count -Exactly
        Should -Invoke -CommandName secedit -Times 1 -Exactly -ParameterFilter {
            $Arguments[0] -eq "/configure" -and
                $Arguments[1] -eq "/cfg" -and
                $Arguments[2] -like "*\inf\defltbase.inf" -and
                $Arguments[3] -eq "/db" -and
                $Arguments[4] -eq "defltbase.sdb"
        }
    }
}

Describe "Invoke-WPFUpdatessecurity" {
    BeforeEach {
        Mock Write-Host { }
        Mock Write-WinUtilLog { }
        Mock New-Item { }
        Mock Set-ItemProperty { }
    }

    It "disables driver metadata and Windows Update driver search" {
        Invoke-WPFUpdatessecurity

        Should -Invoke -CommandName New-Item -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -and $Force -eq $true
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -and
                $Name -eq "PreventDeviceMetadataFromNetwork" -and
                $Type -eq "DWord" -and
                $Value -eq 1
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -and
                $Name -eq "DontPromptForWindowsUpdate" -and
                $Type -eq "DWord" -and
                $Value -eq 1
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -and
                $Name -eq "DontSearchWindowsUpdate" -and
                $Type -eq "DWord" -and
                $Value -eq 1
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -and
                $Name -eq "DriverUpdateWizardWuSearchEnabled" -and
                $Type -eq "DWord" -and
                $Value -eq 0
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -and
                $Name -eq "ExcludeWUDriversInQualityUpdate" -and
                $Type -eq "DWord" -and
                $Value -eq 1
        }
    }

    It "sets recommended update deferral and auto-reboot policy values" {
        Invoke-WPFUpdatessecurity

        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -and
                $Name -eq "BranchReadinessLevel" -and
                $Type -eq "DWord" -and
                $Value -eq 20
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -and
                $Name -eq "DeferFeatureUpdatesPeriodInDays" -and
                $Type -eq "DWord" -and
                $Value -eq 365
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -and
                $Name -eq "DeferQualityUpdatesPeriodInDays" -and
                $Type -eq "DWord" -and
                $Value -eq 4
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -and
                $Name -eq "NoAutoRebootWithLoggedOnUsers" -and
                $Type -eq "DWord" -and
                $Value -eq 1
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -and
                $Name -eq "AUPowerManagement" -and
                $Type -eq "DWord" -and
                $Value -eq 0
        }
    }
}
