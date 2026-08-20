#===========================================================================
# Tests - Entry ToolTip Helper
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilEntryToolTip.ps1")
    . (Join-Path $script:repoRoot "functions\private\Update-WinUtilSelections.ps1")

    $applications = Get-Content (Join-Path $script:repoRoot "config\applications.json") -Raw | ConvertFrom-Json
    $applicationsHashtable = @{}
    foreach ($property in $applications.PSObject.Properties) {
        $applicationsHashtable["WPFInstall$($property.Name)"] = $property.Value
    }
    $appx = Get-Content (Join-Path $script:repoRoot "config\appx.json") -Raw | ConvertFrom-Json
    $appxHashtable = @{}
    foreach ($property in $appx.PSObject.Properties) {
        $appxHashtable[$property.Name] = $property.Value
    }
    $script:selectionConfigs = @{
        applicationsHashtable = $applicationsHashtable
        tweaks                 = Get-Content (Join-Path $script:repoRoot "config\tweaks.json") -Raw | ConvertFrom-Json
        feature                = Get-Content (Join-Path $script:repoRoot "config\feature.json") -Raw | ConvertFrom-Json
        appxHashtable          = $appxHashtable
    }

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

    $appRendererPath = Join-Path $script:repoRoot "functions\private\Initialize-InstallAppEntry.ps1"
    $script:appRenderer = Get-Content $appRendererPath -Raw

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
    It "leaves unsupported controls unlabelled" {
        # Comboboxes and radio buttons are not representable in the flat preset format.
        # Toggle keys can be imported, but preset execution does not apply their state.
        $script:rendererClauses["Toggle"] | Should -BeFalse
        $script:rendererClauses["Combobox"] | Should -BeFalse
        $script:rendererClauses["RadioButton"] | Should -BeFalse
    }

    It "labels entries created by the application renderer" {
        $script:appRenderer | Should -Match '\$border\.ToolTip\s*=\s*Get-WinUtilEntryToolTip\s+-Description\s+\$app\.description\s+-Key\s+\$appKey'
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
                configs          = $script:selectionConfigs
            }

            { Update-WinUtilSelections -flatJson @($entry.Key) } |
                Should -Not -Throw -Because "$($entry.Config).json key '$($entry.Key)' is shown as a preset key"

            $imported = @($sync.Values | ForEach-Object { $_ })
            $imported | Should -Contain $entry.Key -Because "importing '$($entry.Key)' must restore that selection"
        }
    }
}
