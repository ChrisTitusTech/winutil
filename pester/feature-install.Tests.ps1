#===========================================================================
# Tests - Feature Installation
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Invoke-WinUtilFeatureInstall.ps1")

    function Enable-WindowsOptionalFeature {
        [CmdletBinding()]
        param(
            [switch]$Online,
            [string]$FeatureName,
            [switch]$All,
            [switch]$NoRestart
        )
    }
    function Write-WinUtilLog {
        param($Message, $Level, $Component)
    }
}

Describe "Invoke-WinUtilFeatureInstall" {
    BeforeEach {
        $script:sync = [Hashtable]::Synchronized(@{
            configs = @{
                feature = [pscustomobject]@{
                    WPFFeaturesMulti = [pscustomobject]@{
                        feature = @("FeatureA", "FeatureB")
                    }
                    WPFFeaturesScriptOnly = [pscustomobject]@{
                        InvokeScript = @("Write-Output 'feature script'")
                    }
                }
            }
        })

        Mock Enable-WindowsOptionalFeature { }
        Mock Write-Host { }
        Mock Write-Warning { }
        Mock Write-WinUtilLog { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
    }

    It "enables every selected feature" {
        Invoke-WinUtilFeatureInstall -CheckBox "WPFFeaturesMulti"

        Should -Invoke -CommandName Enable-WindowsOptionalFeature -Times 1 -Exactly -ParameterFilter {
            $FeatureName -eq "FeatureA"
        }
        Should -Invoke -CommandName Enable-WindowsOptionalFeature -Times 1 -Exactly -ParameterFilter {
            $FeatureName -eq "FeatureB"
        }
    }

    It "continues with the remaining features when one fails" {
        Mock Enable-WindowsOptionalFeature { throw "simulated missing feature" } -ParameterFilter {
            $FeatureName -eq "FeatureA"
        }

        { Invoke-WinUtilFeatureInstall -CheckBox "WPFFeaturesMulti" } | Should -Not -Throw

        Should -Invoke -CommandName Enable-WindowsOptionalFeature -Times 1 -Exactly -ParameterFilter {
            $FeatureName -eq "FeatureA"
        }
        Should -Invoke -CommandName Enable-WindowsOptionalFeature -Times 1 -Exactly -ParameterFilter {
            $FeatureName -eq "FeatureB"
        }
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and $Message -like "*FeatureA*"
        }
    }

    It "runs the configured feature scripts" {
        Invoke-WinUtilFeatureInstall -CheckBox "WPFFeaturesScriptOnly"

        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Message -eq "Feature action completed: WPFFeaturesScriptOnly"
        }
    }
}
