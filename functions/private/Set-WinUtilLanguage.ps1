function Set-WinUtilLanguage {
    <#
    .SYNOPSIS
        Applies a UI language to every localized string resource in the window.

    .DESCRIPTION
        Locale files under config/locales are embedded by Compile.ps1 into
        $sync.configs.locales. Each key is written into the window resources, which the XAML
        references through {DynamicResource <key>}. Changing the language at runtime updates the
        whole interface immediately. Arabic also switches the window to right-to-left flow.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Language
    )

    $locales = $sync.configs.locales
    $locale = if ($locales -is [System.Collections.IDictionary]) { $locales[$Language] } else { $locales.$Language }
    if ($null -eq $locale) {
        Write-WinUtilLog -Level "WARN" -Component "UI" -Message "Locale '$Language' was not found."
        return
    }

    foreach ($entry in $locale.PSObject.Properties) {
        $sync.Form.Resources[$entry.Name] = [string]$entry.Value
    }

    $sync.preferences.language = $Language
    if (Get-Command Save-WinUtilPreferences -ErrorAction SilentlyContinue) { Save-WinUtilPreferences }

    $direction = Get-WinUtilLanguageDirection -Language $Language
    if ($null -ne $sync.Form -and $null -ne $sync.Form.Dispatcher) {
        $sync.Form.FlowDirection = $direction
    }

    # Refresh the open settings dialog in place so its texts follow the new language without
    # requiring the user to close and reopen it.
    if ($null -ne $sync -and $sync.ContainsKey("SettingsDialog") -and $null -ne $sync.SettingsDialog) {
        try {
            $dialog = $sync.SettingsDialog
            $dialog.FlowDirection = $direction
            $resources = @{}
            foreach ($p in $locale.PSObject.Properties) { $resources[$p.Name] = [string]$p.Value }
            Set-WinUtilDialogText -Root $dialog -Resources $resources
        } catch { }
    }

    # On the Install tab, keep the Actions panel on the leading side: right for RTL
    # languages, left for LTR ones. The app cards themselves stay LTR.
    if ($null -ne $sync -and $sync.ContainsKey("WPFInstallContentGrid") -and $null -ne $sync.WPFInstallContentGrid) {
        $sync.WPFInstallContentGrid.FlowDirection = $direction
    }

    # Re-render the guide card so its text follows the new language immediately, without
    # needing to leave and re-enter the step.
    if ($sync.UiMode -eq "Setup" -and $sync.GuideStep) {
        try { Set-WinUtilGuideStep -Step ([int]$sync.GuideStep) } catch { }
    }

    # The config-backed tabs are built once and cached. Force a rebuild so their labels follow
    # the new language (they were generated with the previous language at warmup/startup).
    if ($sync.InitializedTabs) {
        foreach ($tab in @("Tweaks", "Config", "AppX")) {
            if ($sync.InitializedTabs.ContainsKey($tab) -or $sync.InitializedTabs.$tab) {
                $sync.InitializedTabs[$tab] = $false
            }
        }
    }

    # The Install tab's Actions panel is built from config at warmup in the startup language.
    # Rebuild just that small panel so its labels/tooltips follow the new language; the app cards
    # themselves stay unchanged and keep their pinned LTR flow.
    if ($null -ne $sync -and $sync.ContainsKey("appscategory") -and $null -ne $sync.appscategory) {
        try {
            $sync.appscategory.Children.Clear()
            Initialize-WPFUI -targetGridName "appscategory"
        } catch { }
    }

    # Rebuild the config-backed panels unconditionally, not only when their tab is visible:
    # the panels may have been built at warmup in the old language and only rendered later.
    foreach ($tab in @("Tweaks", "Config", "AppX")) {
        if ($null -eq $sync.InitializedTabs -or -not $sync.InitializedTabs[$tab]) {
            try { Initialize-WinUtilTabContent -TabName $tab } catch { }
        }
    }

    # If a config-backed tab is currently visible, re-select it so the rebuilt content is shown.
    $currentTab = [string]$sync.currentTab
    if ($currentTab -in @("Tweaks", "Config", "AppX")) {
        switch ($currentTab) {
            "Tweaks" { $sync.InitializedTabs["Tweaks"] = $false; $clicked = "WPFTab2BT" }
            "Config" { $sync.InitializedTabs["Config"] = $false; $clicked = "WPFTab3BT" }
            "AppX" { $sync.InitializedTabs["AppX"] = $false; $clicked = "WPFTab6BT" }
        }
        try { Invoke-WPFTab $clicked } catch { }
    }

    Write-WinUtilLog -Component "UI" -Message "Interface language: $Language."
}

function Get-WinUtilLanguage {
    <#
    .SYNOPSIS
        Returns the currently selected interface language.
    #>
    if ($sync.preferences -and $sync.preferences.language) { return [string]$sync.preferences.language }
    return "en"
}
