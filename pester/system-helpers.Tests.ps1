#===========================================================================
# Tests - System Helper Functions
#===========================================================================

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilCurrentSystem.ps1")
    . (Join-Path $script:repoRoot "functions\private\Set-WinUtilRegistry.ps1")
    . (Join-Path $script:repoRoot "functions\private\Set-WinUtilService.ps1")

    function winget {
        param([Parameter(ValueFromRemainingArguments = $true)]$Arguments)
    }
    function choco {
        param([Parameter(ValueFromRemainingArguments = $true)]$Arguments)
    }
    function Write-WinUtilLog { }
}

Describe "Invoke-WinUtilCurrentSystem installed apps" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            configs = [pscustomobject]@{
                applicationsHashtable = @{
                    WPFInstallGit = [pscustomobject]@{ winget = "Git.Git"; choco = "git" }
                    WPFInstallChatGPT = [pscustomobject]@{ winget = "msstore:9NT1R1C2HH7J"; choco = "na" }
                    WPFInstallMissing = [pscustomobject]@{ winget = "Git"; choco = "missing" }
                }
            }
        })

        Mock winget {
            $global:LASTEXITCODE = 0
            $script:wingetArguments = @($Arguments)
            @(
                "Name  Id  Version  Source",
                "--------------------------------",
                "Git  Git.Git  2.0  winget",
                "ChatGPT  9NT1R1C2HH7J  1.0  msstore"
            )
        }
        Mock choco {
            $script:chocoArguments = @($Arguments)
            @("Chocolatey v2", "git 2.0", "2 packages installed.")
        }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name wingetArguments -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name chocoArguments -Scope Script -ErrorAction SilentlyContinue
    }

    It "matches single standard and Microsoft Store package IDs" {
        $result = @(Invoke-WinUtilCurrentSystem -CheckBox "winget")

        $result | Should -HaveCount 2
        $result | Should -Contain "WPFInstallGit"
        $result | Should -Contain "WPFInstallChatGPT"
        $result | Should -Not -Contain "WPFInstallMissing"
        Should -Invoke -CommandName winget -Times 1 -Exactly
        $script:wingetArguments | Should -Be @("list", "--accept-source-agreements", "--disable-interactivity")
    }

    It "fails promptly when Winget cannot list applications" {
        Mock winget {
            $global:LASTEXITCODE = 1
            "winget failed"
        }

        { Invoke-WinUtilCurrentSystem -CheckBox "winget" } | Should -Throw "winget list failed with exit code 1."
    }

    It "matches the primary Chocolatey package ID in one list call" {
        $result = @(Invoke-WinUtilCurrentSystem -CheckBox "choco")

        $result | Should -Be @("WPFInstallGit")
        Should -Invoke -CommandName choco -Times 1 -Exactly
        $script:chocoArguments | Should -Be @("list")
    }
}

Describe "Set-WinUtilRegistry" {
    BeforeEach {
        $script:testPathResults = @{}

        Mock Write-Host { }
        Mock Write-Warning { }
        Mock Write-WinUtilLog { }
        Mock Test-Path {
            param([string]$Path)

            if ($script:testPathResults.ContainsKey($Path)) {
                return $script:testPathResults[$Path]
            }

            throw "Unexpected Test-Path call: $Path"
        }
        Mock New-PSDrive { }
        Mock New-Item { }
        Mock Set-ItemProperty { }
        Mock Remove-ItemProperty { }
    }

    It "creates a missing registry path before setting a value" {
        $registryPath = "HKCU:\Software\WinUtilTest"
        $script:testPathResults["HKU:\"] = $true
        $script:testPathResults[$registryPath] = $false

        Set-WinUtilRegistry -Path $registryPath -Name "Enabled" -Type "DWord" -Value "1"

        Should -Invoke -CommandName New-PSDrive -Times 0 -Exactly
        Should -Invoke -CommandName New-Item -Times 1 -Exactly -ParameterFilter {
            $Path -eq $registryPath -and $Force -eq $true -and $ErrorAction -eq "Stop"
        }
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq $registryPath -and
                $Name -eq "Enabled" -and
                $Type -eq "DWord" -and
                $Value -eq "1" -and
                $Force -eq $true -and
                $ErrorAction -eq "Stop"
        }
        Should -Invoke -CommandName Remove-ItemProperty -Times 0 -Exactly
    }

    It "creates the HKU PSDrive when it is missing" {
        $registryPath = "HKCU:\Software\WinUtilTest"
        $script:testPathResults["HKU:\"] = $false
        $script:testPathResults[$registryPath] = $true

        Set-WinUtilRegistry -Path $registryPath -Name "Enabled" -Type "DWord" -Value "1"

        Should -Invoke -CommandName New-PSDrive -Times 1 -Exactly -ParameterFilter {
            $PSProvider -eq "Registry" -and
                $Name -eq "HKU" -and
                $Root -eq "HKEY_USERS"
        }
        Should -Invoke -CommandName New-Item -Times 0 -Exactly
        Should -Invoke -CommandName Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq $registryPath -and $Name -eq "Enabled" -and $Type -eq "DWord" -and $Value -eq "1"
        }
    }

    It "removes a registry value when requested" {
        $registryPath = "HKLM:\Software\WinUtilTest"
        $script:testPathResults["HKU:\"] = $true
        $script:testPathResults[$registryPath] = $true

        Set-WinUtilRegistry -Path $registryPath -Name "ObsoleteValue" -Type "String" -Value "<RemoveEntry>"

        Should -Invoke -CommandName Set-ItemProperty -Times 0 -Exactly
        Should -Invoke -CommandName Remove-ItemProperty -Times 1 -Exactly -ParameterFilter {
            $Path -eq $registryPath -and
                $Name -eq "ObsoleteValue" -and
                $Force -eq $true -and
                $ErrorAction -eq "Stop"
        }
    }
}

Describe "Set-WinUtilService" {
    BeforeEach {
        Mock Write-Host { }
        Mock Write-Warning { }
        Mock Write-WinUtilLog { }
        Mock Get-Service { }
        Mock Set-Service { }
    }

    It "sets the startup type for an existing service" {
        Mock Get-Service {
            [pscustomobject]@{
                Name = "DiagTrack"
                StartType = "Automatic"
            }
        } -ParameterFilter { $Name -eq "DiagTrack" -and $ErrorAction -eq "Stop" }

        Set-WinUtilService -Name "DiagTrack" -StartupType "Disabled"

        Should -Invoke -CommandName Get-Service -Times 1 -Exactly -ParameterFilter {
            $Name -eq "DiagTrack" -and $ErrorAction -eq "Stop"
        }
        Should -Invoke -CommandName Set-Service -Times 1 -Exactly -ParameterFilter {
            $StartupType -eq "Disabled" -and $ErrorAction -eq "Stop"
        }
    }

    It "does not change a service that already has the requested startup type" {
        Mock Get-Service {
            [pscustomobject]@{
                Name = "DiagTrack"
                StartType = "Disabled"
            }
        } -ParameterFilter { $Name -eq "DiagTrack" -and $ErrorAction -eq "Stop" }

        Set-WinUtilService -Name "DiagTrack" -StartupType "Disabled"

        Should -Invoke -CommandName Get-Service -Times 1 -Exactly
        Should -Invoke -CommandName Set-Service -Times 0 -Exactly
    }

    It "does not call Set-Service when the service is missing" {
        Mock Get-Service {
            $exception = [Microsoft.PowerShell.Commands.ServiceCommandException]::new("Cannot find any service with service name '$Name'.")
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $exception,
                "NoServiceFoundForGivenName,Microsoft.PowerShell.Commands.GetServiceCommand",
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $Name
            )
            throw $errorRecord
        } -ParameterFilter { $Name -eq "MissingService" -and $ErrorAction -eq "Stop" }

        Set-WinUtilService -Name "MissingService" -StartupType "Disabled"

        Should -Invoke -CommandName Get-Service -Times 1 -Exactly -ParameterFilter {
            $Name -eq "MissingService" -and $ErrorAction -eq "Stop"
        }
        Should -Invoke -CommandName Set-Service -Times 0 -Exactly
        Should -Invoke -CommandName Write-Warning -Times 1 -Exactly -ParameterFilter {
            $Message -eq "Service MissingService was not found."
        }
    }
}
