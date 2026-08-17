#===========================================================================
# Tests - Entry ToolTip Helper
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilEntryToolTip.ps1")
}

Describe "Get-WinUtilEntryToolTip" {
    It "appends the preset key after the description" {
        Get-WinUtilEntryToolTip -Description "Fast private browser" -Key "WPFInstallBrave" |
            Should -Be "Fast private browser`n`nPreset key: WPFInstallBrave"
    }

    It "returns only the key line when description is null" {
        Get-WinUtilEntryToolTip -Description $null -Key "WPFTweaksTele" |
            Should -Be "Preset key: WPFTweaksTele"
    }

    It "returns only the key line when description is whitespace" {
        Get-WinUtilEntryToolTip -Description "   " -Key "WPFTweaksTele" |
            Should -Be "Preset key: WPFTweaksTele"
    }

    It "returns a plain string, not a UI object" {
        (Get-WinUtilEntryToolTip -Description "x" -Key "WPFTweaksTele").GetType().Name |
            Should -Be "String"
    }
}
