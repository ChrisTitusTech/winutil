function Set-WinUtilLanguage {
    <#
    .SYNOPSIS
        Switches the UI language immediately: rebuilds rendered config entries,
        re-applies static text injection, and persists the preference. On
        failure the previous language state is restored, the current tab is
        re-rendered in that state, and the error logged, so a failed switch
        never leaves the UI blank, half-translated, or out of sync with the
        persisted preference.

    .PARAMETER Language
        A language code present in config/i18n.json (e.g. "en", "zh-CN").
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Language
    )

    $previousLanguage = $sync.language
    $previousTextTable = $sync.TextTable
    $previousReverseTextTable = $sync.ReverseTextTable

    # Rebuild the already-rendered tab in the current language state and
    # re-wire everything that re-rendering regenerates: config buttons need
    # their click handlers re-attached (the registration cache still holds the
    # discarded controls' names), the package-manager radios need their
    # one-time preference handlers, an active search must be re-applied so
    # non-matching entries stay hidden, and the ISO placeholder lines (TextBox,
    # skipped by the tree walk) must track the new language so
    # Write-WinUtilISOLog can still replace the ready message.
    $rebuildUI = {
        $sync.Buttons = $null
        $sync.InitializedTabs = @{}
        Initialize-WinUtilTabContent -TabName $sync.currentTab
        Invoke-WinUtilUILanguage

        if ($sync.currentTab -eq "Install" -and $sync.WingetRadioButton -and $sync.preferences) {
            $sync.ChocoRadioButton.Add_Checked({ $sync.preferences.packagemanager = "Choco" })
            $sync.WingetRadioButton.Add_Checked({ $sync.preferences.packagemanager = "Winget" })
            switch ($sync.preferences.packagemanager) {
                "Choco" { $sync.ChocoRadioButton.IsChecked = $true; break }
                "Winget" { $sync.WingetRadioButton.IsChecked = $true; break }
            }
        }

        # Reapply an active search so entries hidden by the previous render
        # stay hidden under the same query after rebuilding.
        if ($sync.SearchBar -and -not [string]::IsNullOrWhiteSpace($sync.SearchBar.Text)) {
            switch ($sync.currentTab) {
                "Install" {
                    $categories = if ($sync.SelectedAppCategories) { $sync.SelectedAppCategories.ToArray() } else { @() }
                    Find-AppsByNameOrDescription -SearchString $sync.SearchBar.Text -Categories $categories
                }
                "Tweaks" { Find-TweaksByNameOrDescription -SearchString $sync.SearchBar.Text }
                "AppX" { Find-TweaksByNameOrDescription -SearchString $sync.SearchBar.Text }
            }
        }

        # ISO placeholders live in TextBoxes (not translated by the tree walk);
        # re-sync the placeholder lines in whichever language they currently
        # hold so the next log write can still replace them.
        $isoPath = $sync["WPFWin11ISOPath"]
        if ($isoPath -and $isoPath.Text -in @("No ISO selected...", (Get-WinUtilText "No ISO selected..."))) {
            $isoPath.Text = Get-WinUtilText "No ISO selected..."
        }
        $statusLog = $sync["WPFWin11ISOStatusLog"]
        if ($statusLog -and $statusLog.Text -in @("Ready. Please select a Windows 11 ISO to begin.", (Get-WinUtilText "Ready. Please select a Windows 11 ISO to begin."))) {
            $statusLog.Text = Get-WinUtilText "Ready. Please select a Windows 11 ISO to begin."
        }
    }

    try {
        # The language list lives in config/i18n.json, not in a ValidateSet.
        if ($sync.configs.i18n.PSObject.Properties.Name -notcontains $Language) {
            throw "Unknown language code '$Language'."
        }

        $sync.language = $Language
        if ($Language -eq "en") {
            # Keep a value->key reverse table from the outgoing language so
            # static text already translated can be restored to English.
            # Controls translated by the forward pass restore from their
            # recorded Uid instead; the reverse table covers the rest.
            $sync.TextTable = $null
            $reverse = @{}
            if ($null -ne $previousTextTable) {
                foreach ($entry in $previousTextTable.GetEnumerator()) {
                    # Duplicate translation values (e.g. "Documentation" and
                    # "Document" both translate to 文档) map to the first key
                    # seen, keeping the reverse table deterministic. Per-control
                    # Uid records restore those controls exactly.
                    if (-not $reverse.ContainsKey([string]$entry.Value)) {
                        $reverse[[string]$entry.Value] = [string]$entry.Key
                    }
                }
            }
            $sync.ReverseTextTable = $reverse
        } else {
            $table = @{}
            $sync.configs.i18n.$Language.strings.PSObject.Properties |
                ForEach-Object { $table[$_.Name] = [string]$_.Value }
            if ($table.Count -eq 0) {
                throw "No translation strings found for language '$Language'."
            }
            $sync.TextTable = $table
            $sync.ReverseTextTable = $null
        }

        & $rebuildUI

        # Persist only after the UI switch succeeded.
        $prefPath = Join-Path $sync.winutildir "preferences.json"
        Set-Content -Path $prefPath -Value (@{ language = $Language } | ConvertTo-Json) -Encoding UTF8
    } catch {
        # Restore the previous language state, re-render the current tab in it,
        # and persist the restored preference so the session and preferences.json
        # stay consistent even when the switch failed halfway.
        $sync.language = $previousLanguage
        $sync.TextTable = $previousTextTable
        $sync.ReverseTextTable = $previousReverseTextTable
        try {
            & $rebuildUI
        } catch {
            Write-WinUtilLog -Component "i18n" -Message "Failed to restore the previous language UI: $_"
        }
        $prefPath = Join-Path $sync.winutildir "preferences.json"
        Set-Content -Path $prefPath -Value (@{ language = $previousLanguage } | ConvertTo-Json) -Encoding UTF8
        Write-WinUtilLog -Component "i18n" -Message "Failed to switch language: $_"
    }
}
