function Set-WinUtilDialogText {
    <#
        .SYNOPSIS
            Applies live locale strings to the settings dialog controls.

        .DESCRIPTION
            The dialog XAML uses {DynamicResource s_*} references, which are resolved during
            XamlReader.Load before any resources can be attached to the standalone window. This
            maps each named control to its locale key and assigns the resolved value explicitly.
    #>
    param(
        [Parameter(Mandatory)]$Root,
        [Parameter(Mandatory)]$Resources
    )

    $map = @{
        'SettingsThemeAuto'          = 's_auto'
        'SettingsThemeDark'          = 's_dark'
        'SettingsThemeLight'         = 's_light'
        'SettingsFontScalingReset'   = 's_settings_reset'
        'SettingsFontScalingApply'   = 's_settings_apply'
        'SettingsImportButton'       = 's_settings_import'
        'SettingsExportButton'       = 's_settings_export'
        'SettingsExportReportButton' = 's_settings_export_report'
        'SettingsAboutButton'        = 's_about'
        'SettingsDocumentationButton'= 's_settings_documentation'
        'SettingsSponsorsButton'     = 's_settings_sponsors'
        'SettingsCloseButton'        = 's_settings_close'
    }
    foreach ($name in $map.Keys) {
        $control = $Root.FindName($name)
        $key = $map[$name]
        if ($null -eq $control) { continue }
        $value = $Resources[$key]
        if ($null -eq $value) { continue }
        try {
            if ($control -is [Windows.Controls.Button] -or $control -is [Windows.Controls.RadioButton]) {
                $control.Content = [string]$value
            } elseif ($control -is [Windows.Controls.TextBlock]) {
                $control.Text = [string]$value
            }
        } catch { }
    }

    # Section headings and labels are TextBlocks named after their locale key.
    $textMap = @{
        'SettingsTitleTextBlock'      = 's_settings_title'
        'SettingsAppearanceTextBlock' = 's_settings_appearance'
        'SettingsThemeLabel'          = 's_settings_theme'
        'SettingsFontSizeLabel'       = 's_settings_font_size'
        'SettingsLanguageTextBlock'   = 's_settings_language'
        'SettingsPackagesTextBlock'   = 's_settings_packages'
        'SettingsDataTextBlock'       = 's_settings_data'
        'SettingsAboutTextBlock'      = 's_settings_about_section'
    }
    foreach ($name in $textMap.Keys) {
        $control = $Root.FindName($name)
        if ($null -eq $control) { continue }
        $value = $Resources[$textMap[$name]]
        if ($null -ne $value) { try { $control.Text = [string]$value } catch { } }
    }
}

function Show-WinUtilSettingsDialog {
    <#
        .SYNOPSIS
            Shows the unified settings dialog.

        .DESCRIPTION
            Builds a standalone WPF window from xaml/settingsDialog.xaml, copies the live theme
            and locale resources from the main window so DynamicResource lookups work, wires every
            control to the existing handler functions, and shows the window modally.
    #>
    # Compile.ps1 embeds the dialog XAML in $sync.settingsDialogXaml, so no filesystem path is
    # needed at runtime (the interface runspace has no usable $PSCommandPath).
    $xamlText = $null
    if ($null -ne $sync -and $sync.ContainsKey("settingsDialogXaml")) { $xamlText = [string]$sync.settingsDialogXaml }
    if ([string]::IsNullOrWhiteSpace($xamlText)) { return }

    [xml]$settingsXaml = $xamlText
    $dialog = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader($settingsXaml)))
    $dialog.Owner = $sync.Form
    $sync.SettingsDialog = $dialog

    # WindowStyle=None removes the OS title bar/frame: drag via the header, close via the header button.
    $dialog.FindName("SettingsHeader").Add_MouseLeftButtonDown({ $dialog.DragMove() })
    $dialog.FindName("SettingsHeaderClose").Add_Click({ $dialog.Close() })

    # DynamicResource references in the dialog XAML are resolved at load time, before we can copy
    # resources onto the window. Assign the live values explicitly instead, then also copy them
    # onto the dialog so any later lookups succeed.
    if ($null -ne $sync.Form -and $null -ne $sync.Form.Resources) {
        foreach ($key in $sync.Form.Resources.Keys) {
            try { $dialog.Resources[$key] = $sync.Form.Resources[$key] } catch { }
        }
        # Read from the active locale config (not only from Form.Resources) so the dialog always
        # shows the current language even if the resource dictionary was not refreshed yet.
        $language = if ($sync.preferences) { $sync.preferences.language } else { "en" }
        $locales = $sync.configs.locales
        $locale = $null
        if ($null -ne $locales) {
            $locale = if ($locales -is [System.Collections.IDictionary]) { $locales[$language] } else { $locales.$language }
        }
        if ($null -ne $locale) {
            $resources = @{}
            foreach ($p in $locale.PSObject.Properties) { $resources[$p.Name] = [string]$p.Value }
            Set-WinUtilDialogText -Root $dialog -Resources $resources
        } else {
            Set-WinUtilDialogText -Root $dialog -Resources $sync.Form.Resources
        }
    }
    $dialog.FlowDirection = $sync.Form.FlowDirection

    # Theme buttons
    $dialog.FindName("SettingsThemeAuto").Add_Click({ Invoke-WinutilThemeChange -theme "Auto" })
    $dialog.FindName("SettingsThemeDark").Add_Click({ Invoke-WinutilThemeChange -theme "Dark" })
    $dialog.FindName("SettingsThemeLight").Add_Click({ Invoke-WinutilThemeChange -theme "Light" })

    # Font scaling
    $slider = $dialog.FindName("SettingsFontScalingSlider")
    $slider.Add_ValueChanged({
        $percentage = [math]::Round($this.Value * 100)
        $valueBlock = $dialog.FindName("SettingsFontScalingValue")
        if ($null -ne $valueBlock) { $valueBlock.Text = "$percentage%" }
    })
    $dialog.FindName("SettingsFontScalingReset").Add_Click({
        $slider.Value = 1.0
        $dialog.FindName("SettingsFontScalingValue").Text = "100%"
    })
    $dialog.FindName("SettingsFontScalingApply").Add_Click({
        Invoke-WinUtilFontScaling -ScaleFactor $slider.Value
    })

    # Language buttons (generated from config/languages.json)
    $languageHost = $dialog.FindName("SettingsLanguageItems")
    $languages = $null
    if ($null -ne $sync.configs) {
        $configs = $sync.configs
        if ($configs -is [System.Collections.IDictionary]) { $languages = $configs["languages"] } else { $languages = $configs.languages }
    }
    if ($null -ne $languages) {
        # Resolve each display name from the active locale so sorting and tooltips read naturally.
        $activeLocale = $null
        if ($null -ne $sync.configs) {
            $lang = if ($sync.preferences) { $sync.preferences.language } else { "en" }
            $locales = $sync.configs.locales
            $activeLocale = if ($locales -is [System.Collections.IDictionary]) { $locales[$lang] } else { $locales.$lang }
        }
        $items = @()
        foreach ($entry in $languages.PSObject.Properties) {
            $code = [string]$entry.Name
            $info = $entry.Value
            $displayKey = if ($info -is [System.Collections.IDictionary]) { $info["displayNameKey"] } else { $info.displayNameKey }
            if ([string]::IsNullOrWhiteSpace([string]$displayKey)) { $displayKey = "s_language_$code" }
            $display = $displayKey
            if ($null -ne $activeLocale) {
                $p = $activeLocale.PSObject.Properties[$displayKey]
                if ($null -ne $p -and -not [string]::IsNullOrWhiteSpace([string]$p.Value)) { $display = [string]$p.Value }
            }
            $items += [pscustomobject]@{ Code = $code; Key = $displayKey; Display = $display }
        }
        $items = @($items | Sort-Object -Property Display)

        foreach ($item in $items) {
            $button = New-Object Windows.Controls.Button
            $button.Height = 28
            $button.MinWidth = 110
            $button.Padding = [System.Windows.Thickness]::new(8, 0, 8, 0)
            $button.Margin = [System.Windows.Thickness]::new(0, 0, 6, 6)
            $button.SetResourceReference([Windows.Controls.Button]::ContentProperty, $item.Key)
            $button.ToolTip = "$($item.Display) ($($item.Code))"
            $button.Tag = $item.Code
            $button.Name = "LanguageButton_$($item.Code -replace '[^A-Za-z0-9_]', '_')"
            $button.Add_Click({
                $selected = [string]$this.Tag
                if (-not [string]::IsNullOrWhiteSpace($selected)) { Set-WinUtilLanguage -Language $selected }
            })
            [void]$languageHost.Children.Add($button)
        }
    }

    # Package manager radios
    $winget = $dialog.FindName("SettingsWingetRadio")
    $choco = $dialog.FindName("SettingsChocoRadio")
    $winget.Add_Checked({ $sync.preferences.packagemanager = "Winget"; if (Get-Command Save-WinUtilPreferences -ErrorAction SilentlyContinue) { Save-WinUtilPreferences } })
    $choco.Add_Checked({ $sync.preferences.packagemanager = "Choco"; if (Get-Command Save-WinUtilPreferences -ErrorAction SilentlyContinue) { Save-WinUtilPreferences } })
    switch ($sync.preferences.packagemanager) {
        "Choco" { $choco.IsChecked = $true; break }
        default { $winget.IsChecked = $true }
    }

    # Data actions
    $dialog.FindName("SettingsImportButton").Add_Click({ Invoke-WPFImpex -type "import" })
    $dialog.FindName("SettingsExportButton").Add_Click({ Invoke-WPFImpex -type "export" })
    $dialog.FindName("SettingsExportReportButton").Add_Click({ Invoke-WPFExportEnvironmentReport })

    # About / docs / sponsors
    $dialog.FindName("SettingsAboutButton").Add_Click({
        $authorInfo = @"
Author   : <a href="https://github.com/ChrisTitusTech">@ChrisTitusTech</a>
UI       : <a href="https://github.com/MyDrift-user">@MyDrift-user</a>, <a href="https://github.com/Marterich">@Marterich</a>
Runspace : <a href="https://github.com/DeveloperDurp">@DeveloperDurp</a>, <a href="https://github.com/Marterich">@Marterich</a>
GitHub   : <a href="https://github.com/ChrisTitusTech/winutil">ChrisTitusTech/winutil</a>
Version  : <a href="https://github.com/ChrisTitusTech/winutil/releases/tag/$($sync.version)">$($sync.version)</a>
"@
        Show-CustomDialog -Title "About" -Message $authorInfo
    })
    $dialog.FindName("SettingsDocumentationButton").Add_Click({ Start-Process "https://winutil.christitus.com/" })
    $dialog.FindName("SettingsSponsorsButton").Add_Click({
        $authorInfo = @"
<a href="https://github.com/sponsors/ChrisTitusTech">Current sponsors for ChrisTitusTech:</a>
"@
        $authorInfo += "`n"
        try {
            $sponsors = Invoke-WinUtilSponsors
            foreach ($sponsor in $sponsors) {
                $authorInfo += "<a href=`"https://github.com/sponsors/ChrisTitusTech`">$sponsor</a>`n"
            }
        } catch {
            $authorInfo += "An error occurred while fetching or processing the sponsors: $_`n"
        }
        Show-CustomDialog -Title "Sponsors" -Message $authorInfo -EnableScroll $true
    })

    $dialog.FindName("SettingsCloseButton").Add_Click({ $dialog.Close() })

    $dialog.ShowDialog() | Out-Null
}
