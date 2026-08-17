#===========================================================================
# Tests - Entry ToolTip Helper
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilEntryToolTip.ps1")
    . (Join-Path $script:repoRoot "functions\private\Update-WinUtilSelections.ps1")

    # Map each control type the renderer handles to whether its branch adds the preset key.
    # Read from the source AST so re-adding the helper to an unsupported branch fails the test.
    $script:rendererClauses = @{}
    $rendererPath = Join-Path $script:repoRoot "functions\public\Invoke-WPFUIElements.ps1"
    $rendererAst = [System.Management.Automation.Language.Parser]::ParseFile($rendererPath, [ref]$null, [ref]$null)
    $typeSwitch = $rendererAst.FindAll({
        $args[0] -is [System.Management.Automation.Language.SwitchStatementAst]
    }, $true) | Where-Object { $_.Clauses.Item1.Extent.Text -contains '"Combobox"' }

    foreach ($clause in $typeSwitch.Clauses) {
        $clauseName = $clause.Item1.Extent.Text.Trim('"')
        $script:rendererClauses[$clauseName] = [bool]($clause.Item2.Extent.Text -match 'Get-WinUtilEntryToolTip')
    }
    $script:rendererClauses["default"] = [bool]($typeSwitch.Default.Extent.Text -match 'Get-WinUtilEntryToolTip')

    # Every entry the renderer draws, with the branch that draws it
    $script:renderedEntries = foreach ($configName in "appnavigation", "tweaks", "feature", "appx") {
        $config = Get-Content (Join-Path $script:repoRoot "config\$configName.json") -Raw | ConvertFrom-Json
        foreach ($property in $config.PSObject.Properties) {
            $clauseName = "default"
            if ($property.Value.Type -and $script:rendererClauses.ContainsKey($property.Value.Type)) {
                $clauseName = $property.Value.Type
            }
            [pscustomobject]@{
                Config = $configName
                Key    = $property.Name
                Clause = $clauseName
            }
        }
    }
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

Describe "Preset key tooltips" {
    It "leaves comboboxes and radio buttons unlabelled" {
        # Neither control is representable in a preset file: it stores a flat list of
        # keys, with no room for a combobox's selected value or a radio group's choice.
        $script:rendererClauses["Combobox"] | Should -BeFalse
        $script:rendererClauses["RadioButton"] | Should -BeFalse
    }

    It "labels every entry with a key the preset importer accepts" {
        $labelled = @($script:renderedEntries | Where-Object { $script:rendererClauses[$_.Clause] })
        $labelled.Count | Should -BeGreaterThan 0

        foreach ($entry in $labelled) {
            $sync = @{
                selectedApps     = [System.Collections.Generic.List[string]]::new()
                selectedTweaks   = [System.Collections.Generic.List[string]]::new()
                selectedToggles  = [System.Collections.Generic.List[string]]::new()
                selectedFeatures = [System.Collections.Generic.List[string]]::new()
                selectedAppx     = [System.Collections.Generic.List[string]]::new()
            }

            { Update-WinUtilSelections -flatJson @($entry.Key) } |
                Should -Not -Throw -Because "$($entry.Config).json key '$($entry.Key)' is shown as a preset key"

            $imported = @($sync.Values | ForEach-Object { $_ })
            $imported | Should -Contain $entry.Key -Because "importing '$($entry.Key)' must restore that selection"
        }
    }
}
