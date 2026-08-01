BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilMultiplaneOverlayState.ps1")
    . (Join-Path $script:repoRoot "functions\private\Set-WinUtilMultiplaneOverlay.ps1")

    function Set-WinUtilRegistry {
        param($Name, $Path, $Type, $Value)
    }
}

Describe "Get-WinUtilMultiplaneOverlayState" {
    It "reports Enabled when neither registry value disables MPO" {
        Mock Get-ItemProperty {
            [pscustomobject]@{ OverlayTestMode = 0; DisableOverlays = 0 }
        }

        Get-WinUtilMultiplaneOverlayState | Should -Be "Enabled"
    }

    It "reports Disabled (Compatibility) when only OverlayTestMode is enabled" {
        Mock Get-ItemProperty {
            if ($Name -eq "OverlayTestMode") {
                return [pscustomobject]@{ OverlayTestMode = 5 }
            }
            return [pscustomobject]@{ DisableOverlays = 0 }
        }

        Get-WinUtilMultiplaneOverlayState | Should -Be "Disabled (Compatibility)"
    }

    It "reports Fully Disabled when DisableOverlays is enabled" {
        Mock Get-ItemProperty {
            if ($Name -eq "OverlayTestMode") {
                return [pscustomobject]@{ OverlayTestMode = 5 }
            }
            return [pscustomobject]@{ DisableOverlays = 1 }
        }

        Get-WinUtilMultiplaneOverlayState | Should -Be "Fully Disabled"
    }

    It "rejects a partial fully disabled state" {
        Mock Get-ItemProperty {
            if ($Name -eq "OverlayTestMode") {
                return [pscustomobject]@{ OverlayTestMode = 0 }
            }
            return [pscustomobject]@{ DisableOverlays = 1 }
        }

        { Get-WinUtilMultiplaneOverlayState } | Should -Throw "Unexpected Multiplane Overlay registry state*"
    }
}

Describe "Set-WinUtilMultiplaneOverlay" {
    BeforeEach {
        $script:registryValues = @{ OverlayTestMode = 0; DisableOverlays = 0 }
        Mock Get-ItemProperty {
            if ($Name -eq "OverlayTestMode") {
                return [pscustomobject]@{ OverlayTestMode = $script:registryValues.OverlayTestMode }
            }
            return [pscustomobject]@{ DisableOverlays = $script:registryValues.DisableOverlays }
        }
        Mock Set-WinUtilRegistry {
            if ($Value -eq "<RemoveEntry>") {
                $script:registryValues.Remove($Name)
                return
            }
            $script:registryValues[$Name] = [int]$Value
        }
    }

    It "writes the compatibility values" {
        Set-WinUtilMultiplaneOverlay -State "Disabled (Compatibility)"

        Should -Invoke Set-WinUtilRegistry -Times 1 -Exactly -ParameterFilter {
            $Name -eq "OverlayTestMode" -and $Value -eq 5
        }
        Should -Invoke Set-WinUtilRegistry -Times 1 -Exactly -ParameterFilter {
            $Name -eq "DisableOverlays" -and $Value -eq 0
        }
    }

    It "writes the fully disabled values" {
        Set-WinUtilMultiplaneOverlay -State "Fully Disabled"

        Should -Invoke Set-WinUtilRegistry -Times 1 -Exactly -ParameterFilter {
            $Name -eq "OverlayTestMode" -and $Value -eq 5
        }
        Should -Invoke Set-WinUtilRegistry -Times 1 -Exactly -ParameterFilter {
            $Name -eq "DisableOverlays" -and $Value -eq 1
        }
    }

    It "throws and restores the previous values when the requested state cannot be verified" {
        Mock Set-WinUtilRegistry {
            if ($Name -eq "DisableOverlays" -and $Value -eq 1) {
                return
            }
            $script:registryValues[$Name] = [int]$Value
        }

        { Set-WinUtilMultiplaneOverlay -State "Fully Disabled" } | Should -Throw "Unable to apply Multiplane Overlay state*"
        $script:registryValues.OverlayTestMode | Should -Be 0
        $script:registryValues.DisableOverlays | Should -Be 0
    }

    It "removes values created by a failed update when they did not previously exist" {
        $script:registryValues.Clear()
        Mock Get-ItemProperty {
            if ($Name -eq "OverlayTestMode") {
                return [pscustomobject]@{ OverlayTestMode = $script:registryValues.OverlayTestMode }
            }
            return [pscustomobject]@{ DisableOverlays = $script:registryValues.DisableOverlays }
        }
        Mock Set-WinUtilRegistry {
            if ($Name -eq "DisableOverlays" -and $Value -eq 1) {
                return
            }
            if ($Value -eq "<RemoveEntry>") {
                $script:registryValues.Remove($Name)
                return
            }
            $script:registryValues[$Name] = [int]$Value
        }

        { Set-WinUtilMultiplaneOverlay -State "Fully Disabled" } | Should -Throw "Unable to apply Multiplane Overlay state*"
        $script:registryValues.ContainsKey("OverlayTestMode") | Should -BeFalse
        $script:registryValues.ContainsKey("DisableOverlays") | Should -BeFalse
    }
}

Describe "Stateful combo-box wiring" {
    It "configures the MPO entry and applies state changes immediately" {
        $config = Get-Content (Join-Path $script:repoRoot "config\tweaks.json") -Raw | ConvertFrom-Json
        $renderer = Get-Content (Join-Path $script:repoRoot "functions\public\Invoke-WPFUIElements.ps1") -Raw

        $config.WPFMultiplaneOverlay.Type | Should -Be "Combobox"
        $config.WPFMultiplaneOverlay.ComboItems | Should -Be @("Enabled", "Disabled (Compatibility)", "Fully Disabled")
        $renderer | Should -Match 'Get-WinUtilMultiplaneOverlayState'
        $renderer | Should -Match 'Set-WinUtilMultiplaneOverlay -State \$selectedItem\.Content'
        $renderer | Should -Match 'Sync-WPFMultiplaneOverlayState -ComboBox \$comboBox'
        $renderer | Should -Match 'Sync-WPFMultiplaneOverlayState -ComboBox \$this'
        $renderer | Should -Not -Match 'StateFunction|ApplyFunction|IsApplying'
    }
}

Describe "Unknown MPO state UI handling" {
    It "provides a non-selectable recovery item without weakening state validation" {
        $stateSync = Get-Content (Join-Path $script:repoRoot "functions\private\Sync-WPFMultiplaneOverlayState.ps1") -Raw

        $stateSync | Should -Match 'Custom / Unknown - select a state'
        $stateSync | Should -Match '\$unknownStateItem\.IsEnabled = \$false'
        $stateSync | Should -Match 'Select one of the supported states to replace these values\.'
    }
}
