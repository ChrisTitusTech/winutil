#===========================================================================
# Tests - Configuration tooltips
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilConfigToolTip.ps1")
}

Describe "Get-WinUtilConfigToolTip" {
    It "appends the configuration key to an existing description" {
        $toolTip = Get-WinUtilConfigToolTip `
            -Description "Installs Mozilla Firefox." `
            -ConfigKey "WPFInstallfirefox"

        $toolTip | Should -Be "Installs Mozilla Firefox.`n`nConfiguration key: WPFInstallfirefox"
    }

    It "shows the configuration key when an entry has no description" {
        Get-WinUtilConfigToolTip -Description "" -ConfigKey "WPFOOSUbutton" |
            Should -Be "Configuration key: WPFOOSUbutton"
    }
}

Describe "Configuration tooltip rendering" {
    It "uses configuration-key tooltips for install entries" {
        $entryScript = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Initialize-InstallAppEntry.ps1") -Raw

        $entryScript | Should -Match '\$border\.ToolTip = Get-WinUtilConfigToolTip -Description \$app\.description -ConfigKey \$appKey'
    }

    It "uses configuration-key tooltips for generated tweak controls" {
        $rendererScript = Get-Content -Path (Join-Path $script:repoRoot "functions\public\Invoke-WPFUIElements.ps1") -Raw

        $rendererScript | Should -Match '\$isSelectableEntry = .*"Toggle", "ToggleButton"'
        $rendererScript | Should -Match '\$isImportableKey = \$entry -match.*WPFTweaks.*WPFToggle.*WPFFeature.*WPFAppx'
        $rendererScript | Should -Match '\$entryToolTip = Get-WinUtilConfigToolTip -Description \$entryInfo\.description -ConfigKey \$entry'
        $rendererScript | Should -Match '\$label\.ToolTip = \$entryInfo\.ToolTip'
        $rendererScript | Should -Match '\$toggleButton\.ToolTip = \$entryInfo\.ToolTip'
        $rendererScript | Should -Match '\$checkBox\.ToolTip = \$entryInfo\.ToolTip'
    }

    It "keeps non-selectable controls out of configuration-key tooltips" {
        $rendererScript = Get-Content -Path (Join-Path $script:repoRoot "functions\public\Invoke-WPFUIElements.ps1") -Raw

        $rendererScript | Should -Not -Match '\$button\.ToolTip = \$entryInfo\.ToolTip'
        $rendererScript | Should -Match '\$label\.ToolTip = \$entryInfo\.Description'
        $rendererScript | Should -Match '\$radioButton\.ToolTip = \$entryInfo\.Description'
    }
}
