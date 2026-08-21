#===========================================================================
# Tests - Multiplane Overlay
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:config = Get-Content (Join-Path $script:repoRoot "config\tweaks.json") -Raw | ConvertFrom-Json
    $script:states = $script:config.WPFMultiplaneOverlay.registry
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilRegistryComboState.ps1")
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilRegistryComboValue.ps1")
    . (Join-Path $script:repoRoot "functions\private\Set-WinUtilRegistryComboState.ps1")

    function Set-WinUtilRegistry {
        param($Name, $Path, $Type, $Value)
    }
}

Describe "Multiplane Overlay configuration" {
    It "keeps every state and registry action in tweaks.json" {
        $script:config.WPFMultiplaneOverlay.Type | Should -Be "Combobox"
        $script:config.WPFMultiplaneOverlay.ComboItems | Should -BeOfType [string]
        $comboItems = @($script:config.WPFMultiplaneOverlay.ComboItems -split "\|")
        $comboItems | Should -Be @("Enabled", "Disabled (Compatibility)", "Fully Disabled")
        $script:states.Count | Should -Be 2
        $script:states[0].Values.PSObject.Properties.Name | Should -Be $comboItems
        $script:states[0].Values.PSObject.Properties.Value | Should -Be @("<RemoveEntry>", "5", "5")
        $script:states[1].Values.PSObject.Properties.Value | Should -Be @("<RemoveEntry>", "<RemoveEntry>", "1")
    }

    It "uses the generic combo registry handler" {
        $renderer = Get-Content (Join-Path $script:repoRoot "functions\public\Invoke-WPFUIElements.ps1") -Raw

        $renderer | Should -Match 'Get-WinUtilRegistryComboState'
        $renderer | Should -Match 'Set-WinUtilRegistryComboState'
        $renderer | Should -Not -Match 'WPFMultiplaneOverlay'
    }
}

Describe "Get-WinUtilRegistryComboState" {
    It "treats missing registry properties and paths as absent" -TestCases @(
        @{ Exception = [System.Management.Automation.PSArgumentException]::new("Property is missing") }
        @{ Exception = [System.Management.Automation.ItemNotFoundException]::new("Path is missing") }
    ) {
        param($Exception)
        Mock Get-ItemProperty { throw $Exception }

        Get-WinUtilRegistryComboState -Registry $script:states | Should -Be "Enabled"
    }

    It "reports Enabled when the values are absent or zero" -TestCases @(
        @{ OverlayTestMode = $null; DisableOverlays = $null }
        @{ OverlayTestMode = 0; DisableOverlays = 0 }
    ) {
        param($OverlayTestMode, $DisableOverlays)
        Mock Get-ItemProperty {
            if ($Name -eq "OverlayTestMode") {
                return [pscustomobject]@{ OverlayTestMode = $OverlayTestMode }
            }
            [pscustomobject]@{ DisableOverlays = $DisableOverlays }
        }

        Get-WinUtilRegistryComboState -Registry $script:states | Should -Be "Enabled"
    }

    It "reports each disabled state" -TestCases @(
        @{ OverlayTestMode = 5; DisableOverlays = $null; Expected = "Disabled (Compatibility)" }
        @{ OverlayTestMode = 5; DisableOverlays = 1; Expected = "Fully Disabled" }
    ) {
        param($OverlayTestMode, $DisableOverlays, $Expected)
        Mock Get-ItemProperty {
            if ($Name -eq "OverlayTestMode") {
                return [pscustomobject]@{ OverlayTestMode = $OverlayTestMode }
            }
            [pscustomobject]@{ DisableOverlays = $DisableOverlays }
        }

        Get-WinUtilRegistryComboState -Registry $script:states | Should -Be $Expected
    }

    It "rejects an unsupported combination" {
        Mock Get-ItemProperty {
            if ($Name -eq "OverlayTestMode") {
                return [pscustomobject]@{ OverlayTestMode = 0 }
            }
            [pscustomobject]@{ DisableOverlays = 1 }
        }

        { Get-WinUtilRegistryComboState -Registry $script:states } | Should -Throw "Registry values do not match a supported state."
    }
}

Describe "Set-WinUtilRegistryComboState" {
    BeforeEach {
        $script:registryValues = @{ OverlayTestMode = 0; DisableOverlays = 0 }
        Mock Get-ItemProperty {
            param($Path, $Name)
            $registryName = [string]$Name
            if ($script:registryValues.ContainsKey($registryName)) {
                $result = [pscustomobject]@{}
                $result | Add-Member -NotePropertyName $registryName -NotePropertyValue $script:registryValues[$registryName]
                return $result
            }
            [pscustomobject]@{}
        }
        Mock Set-WinUtilRegistry {
            param($Name, $Path, $Type, $Value)
            if ($Value -eq "<RemoveEntry>") {
                $script:registryValues.Remove($Name)
            } else {
                $script:registryValues[$Name] = [int]$Value
            }
        }
    }

    It "applies each configured state" -TestCases @(
        @{ State = "Enabled"; OverlayTestMode = $null; DisableOverlays = $null }
        @{ State = "Disabled (Compatibility)"; OverlayTestMode = 5; DisableOverlays = $null }
        @{ State = "Fully Disabled"; OverlayTestMode = 5; DisableOverlays = 1 }
    ) {
        param($State, $OverlayTestMode, $DisableOverlays)

        Set-WinUtilRegistryComboState -Registry $script:states -State $State

        $script:registryValues.OverlayTestMode | Should -Be $OverlayTestMode
        $script:registryValues.DisableOverlays | Should -Be $DisableOverlays
    }

    It "restores previous values when verification fails" {
        Mock Set-WinUtilRegistry {
            param($Name, $Path, $Type, $Value)
            if ($Name -eq "DisableOverlays" -and $Value -eq 1) {
                return
            }
            if ($Value -eq "<RemoveEntry>") {
                $script:registryValues.Remove($Name)
            } else {
                $script:registryValues[$Name] = [int]$Value
            }
        }

        { Set-WinUtilRegistryComboState -Registry $script:states -State "Fully Disabled" } | Should -Throw "Unable to apply registry state*"
        $script:registryValues.OverlayTestMode | Should -Be 0
        $script:registryValues.DisableOverlays | Should -Be 0
    }

    It "restores absence when a state cannot be applied" {
        $script:registryValues.Clear()
        Mock Set-WinUtilRegistry {
            param($Name, $Path, $Type, $Value)
            if ($Name -eq "DisableOverlays" -and $Value -eq 1) {
                return
            }
            if ($Value -eq "<RemoveEntry>") {
                $script:registryValues.Remove($Name)
            } else {
                $script:registryValues[$Name] = [int]$Value
            }
        }

        { Set-WinUtilRegistryComboState -Registry $script:states -State "Fully Disabled" } | Should -Throw "Unable to apply registry state*"
        $script:registryValues.ContainsKey("OverlayTestMode") | Should -BeFalse
        $script:registryValues.ContainsKey("DisableOverlays") | Should -BeFalse
    }

    It "reports when the previous values cannot be restored" {
        Mock Set-WinUtilRegistry {
            param($Name, $Path, $Type, $Value)
            if (($Name -eq "DisableOverlays" -and $Value -eq 1) -or ($Name -eq "OverlayTestMode" -and $Value -eq 0)) {
                return
            }
            if ($Value -eq "<RemoveEntry>") {
                $script:registryValues.Remove($Name)
            } else {
                $script:registryValues[$Name] = [int]$Value
            }
        }

        { Set-WinUtilRegistryComboState -Registry $script:states -State "Fully Disabled" } | Should -Throw "*previous registry state could not be restored*"
    }
}
