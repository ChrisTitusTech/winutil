function Set-WinUtilLanguage {
    <#
    .SYNOPSIS
        Switches the WinUtil UI language by applying locale
        translations to config objects and XAML elements.
    .PARAMETER Language
        The locale code (e.g., "en", "zh-TW").
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Language
    )

    if (-not $sync.configs.locales) { return }

    # Save original English values on first call
    if (-not $sync.originalConfigs) {
        $sync.originalConfigs = @{}
        $configNames = @(
            "appnavigation", "tweaks",
            "feature", "applications"
        )
        foreach ($cn in $configNames) {
            $json = $sync.configs.$cn |
                ConvertTo-Json -Depth 4 -Compress
            $sync.originalConfigs[$cn] =
                $json | ConvertFrom-Json
        }
    }

    $sync.currentLanguage = $Language

    # Restore English originals
    foreach ($cn in $sync.originalConfigs.Keys) {
        $json = $sync.originalConfigs[$cn] |
            ConvertTo-Json -Depth 4 -Compress
        $sync.configs.$cn = $json | ConvertFrom-Json
    }

    # Rebuild applicationsHashtable from restored config
    $sync.configs.applicationsHashtable = @{}
    $sync.configs.applications.PSObject.Properties |
        ForEach-Object {
            $sync.configs.applicationsHashtable[$_.Name] =
                $_.Value
        }

    if ($Language -eq "en") {
        Set-WinUtilLanguageUI
        return
    }

    $localeData = $sync.configs.locales.$Language
    if (-not $localeData) {
        Write-Warning "Locale '$Language' not found"
        return
    }

    # Apply config translations
    $configNames = @("appnavigation", "tweaks", "feature")
    foreach ($cn in $configNames) {
        $translations = $localeData.$cn
        if (-not $translations) { continue }

        foreach ($prop in $translations.PSObject.Properties) {
            $entry = $sync.configs.$cn.($prop.Name)
            if (-not $entry) { continue }

            foreach ($f in $prop.Value.PSObject.Properties) {
                $fname = $f.Name
                if ($entry.PSObject.Properties[$fname]) {
                    $entry.$fname = $f.Value
                }
            }
        }
    }

    # Apply application translations
    $appTr = $localeData.applications
    if ($appTr) {
        foreach ($prop in $appTr.PSObject.Properties) {
            $appKey = "WPFInstall$($prop.Name)"
            $fields = $prop.Value

            $targets = @(
                $sync.configs.applicationsHashtable[$appKey],
                $sync.configs.applications.$appKey
            )

            foreach ($target in $targets) {
                if (-not $target) { continue }
                foreach ($f in $fields.PSObject.Properties) {
                    $fname = $f.Name
                    if ($target.PSObject.Properties[$fname]) {
                        $target.$fname = $f.Value
                    }
                }
            }
        }
    }

    $catMap = $localeData.categories
    if ($catMap) {
        $configNames = @(
            "appnavigation", "tweaks",
            "feature", "applications"
        )
        foreach ($cn in $configNames) {
            foreach ($prop in
                $sync.configs.$cn.PSObject.Properties) {
                $entry = $prop.Value
                $catField = if ($entry.PSObject.Properties["category"]) {
                    "category"
                } elseif ($entry.PSObject.Properties["Category"]) {
                    "Category"
                } else { $null }
                if (-not $catField) { continue }
                $orig = $entry.$catField
                if ($catMap.PSObject.Properties[$orig]) {
                    $entry.$catField = $catMap.$orig
                }
            }
        }
    }

    Set-WinUtilLanguageUI
}

function Set-WinUtilLanguageUI {
    <#
    .SYNOPSIS
        Updates XAML UI elements with current language strings.
    #>

    $lang = $sync.currentLanguage
    $localeData = if ($lang -and $lang -ne "en") {
        $sync.configs.locales.$lang
    } else { $null }

    $ui = if ($localeData) { $localeData.ui } else { $null }

    # Helper to get UI string with English fallback
    $getStr = {
        param([string]$Key, [string]$Default)
        if ($ui -and $ui.PSObject.Properties[$Key]) {
            return $ui.$Key
        }
        return $Default
    }

    # Tab buttons
    $tabMap = @{
        "WPFTab1BT" = @{ key = "tab_install"; default = "Install" }
        "WPFTab2BT" = @{ key = "tab_tweaks"; default = "Tweaks" }
        "WPFTab3BT" = @{ key = "tab_config"; default = "Config" }
        "WPFTab4BT" = @{ key = "tab_updates"; default = "Updates" }
    }

    foreach ($btnName in $tabMap.Keys) {
        $btn = $sync[$btnName]
        if (-not $btn) { continue }
        $info = $tabMap[$btnName]
        $text = & $getStr $info.key $info.default
        $textBlock = $btn.Content
        if ($textBlock -and
            $textBlock.GetType().Name -eq "TextBlock") {
            $textBlock.Inlines.Clear()
            $run = New-Object Windows.Documents.Run
            $run.Text = $text
            $textBlock.Inlines.Add($run)
        }
    }

    # SearchBar tooltip
    $sb = $sync["SearchBar"]
    if ($sb) {
        $sb.ToolTip = & $getStr "search_tooltip" `
            "Press Ctrl-F and type app name to filter application list below. Press Esc to reset the filter"
    }

    # Theme button and menu items
    $thBtn = $sync["ThemeButton"]
    if ($thBtn) {
        $thBtn.ToolTip = & $getStr "theme_tooltip" `
            "Change the Winutil UI Theme"
    }

    $themeItems = @{
        "AutoThemeMenuItem" = @{
            hKey = "theme_auto"; hDef = "Auto"
            tKey = "theme_auto_tooltip"
            tDef = "Follow the Windows Theme"
        }
        "DarkThemeMenuItem" = @{
            hKey = "theme_dark"; hDef = "Dark"
            tKey = "theme_dark_tooltip"
            tDef = "Use Dark Theme"
        }
        "LightThemeMenuItem" = @{
            hKey = "theme_light"; hDef = "Light"
            tKey = "theme_light_tooltip"
            tDef = "Use Light Theme"
        }
    }

    foreach ($itemName in $themeItems.Keys) {
        $item = $sync[$itemName]
        if (-not $item) { continue }
        $info = $themeItems[$itemName]
        $item.Header = & $getStr $info.hKey $info.hDef
        $item.ToolTip = & $getStr $info.tKey $info.tDef
    }

    # Font scaling popup
    $fsBtn = $sync["FontScalingButton"]
    if ($fsBtn) {
        $fsBtn.ToolTip = & $getStr "font_scaling_tooltip" `
            "Adjust Font Scaling for Accessibility"
    }

    # Settings menu items
    $settingsItems = @{
        "ImportMenuItem" = @{
            hKey = "settings_import"; hDef = "Import"
            tKey = "settings_import_tooltip"
            tDef = "Import Configuration from exported file."
        }
        "ExportMenuItem" = @{
            hKey = "settings_export"; hDef = "Export"
            tKey = "settings_export_tooltip"
            tDef = "Export Selected Elements and copy execution command to clipboard."
        }
        "AboutMenuItem" = @{
            hKey = "settings_about"; hDef = "About"
        }
        "SponsorMenuItem" = @{
            hKey = "settings_sponsors"; hDef = "Sponsors"
        }
    }

    foreach ($itemName in $settingsItems.Keys) {
        $item = $sync[$itemName]
        if (-not $item) { continue }
        $info = $settingsItems[$itemName]
        $item.Header = & $getStr $info.hKey $info.hDef
        if ($info.tKey) {
            $item.ToolTip = & $getStr $info.tKey $info.tDef
        }
    }

    # Tweaks tab preset buttons
    $tweakBtns = @{
        "WPFstandard" = @{
            key = "preset_standard"; default = " Standard "
        }
        "WPFminimal" = @{
            key = "preset_minimal"; default = " Minimal "
        }
        "WPFClearTweaksSelection" = @{
            key = "preset_clear"; default = " Clear "
        }
        "WPFGetInstalledTweaks" = @{
            key = "preset_get_installed"
            default = " Get Installed "
        }
        "WPFTweaksbutton" = @{
            key = "tweaks_run"; default = "Run Tweaks"
        }
        "WPFUndoall" = @{
            key = "tweaks_undo"
            default = "Undo Selected Tweaks"
        }
    }

    foreach ($btnName in $tweakBtns.Keys) {
        $btn = $sync[$btnName]
        if (-not $btn) { continue }
        $info = $tweakBtns[$btnName]
        $btn.Content = & $getStr $info.key $info.default
    }

    # Updates tab buttons
    $updateBtns = @{
        "WPFUpdatesdefault" = @{
            key = "updates_default"
            default = "Default Settings"
        }
        "WPFUpdatessecurity" = @{
            key = "updates_security"
            default = "Security Settings"
        }
        "WPFUpdatesdisable" = @{
            key = "updates_disable"
            default = "Disable All Updates"
        }
    }

    foreach ($btnName in $updateBtns.Keys) {
        $btn = $sync[$btnName]
        if (-not $btn) { continue }
        $info = $updateBtns[$btnName]
        $btn.Content = & $getStr $info.key $info.default
    }

    $recLabel = $sync["RecommendedSelectionsLabel"]
    if ($recLabel) {
        $recLabel.Content =
            & $getStr "recommended_selections" `
            "Recommended Selections:"
    }

    $langBtn = $sync["LanguageButton"]
    if ($langBtn -and $localeData._metadata) {
        $langBtn.ToolTip = & $getStr "language_tooltip" `
            "Change Language"
    }
}

function Get-WinUtilAvailableLanguages {
    <#
    .SYNOPSIS
        Returns a list of available languages from locales.
    #>
    $languages = @()
    $languages += [PSCustomObject]@{
        Code = "en"
        Name = "English"
    }

    if ($sync.configs.locales) {
        foreach ($prop in
            $sync.configs.locales.PSObject.Properties) {
            if ($prop.Name -eq "en") { continue }
            $locale = $prop.Value
            $name = if ($locale._metadata -and
                $locale._metadata.name) {
                $locale._metadata.name
            } else { $prop.Name }

            $languages += [PSCustomObject]@{
                Code = $prop.Name
                Name = $name
            }
        }
    }

    return $languages
}
