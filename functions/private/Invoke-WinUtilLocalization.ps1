function Invoke-WinUtilLocalization {
    <#
    .SYNOPSIS
        Applies localization to the WinUtil UI by loading translated strings from a locale JSON file.
    .PARAMETER Language
        The language code to apply (e.g., "en-US", "fr-FR").
        Defaults to "en-US" if not specified or if the locale file is not found.
    #>
    param (
        [Parameter(Mandatory = $false)]
        [string]$Language = "en-US"
    )

    # Load the locale data
    $localeData = $null
    if ($sync.configs.locales -and $sync.configs.locales[$Language]) {
        $localeData = $sync.configs.locales[$Language]
    }

    if (-not $localeData) {
        Write-Host "Locale '$Language' not found. Falling back to en-US."
        if ($sync.configs.locales -and $sync.configs.locales["en-US"]) {
            $localeData = $sync.configs.locales["en-US"]
            $Language = "en-US"
        }
        else {
            Write-Host "No locale files found. Skipping localization."
            return
        }
    }

    $sync.currentLanguage = $Language
    Write-Debug "Applying locale: $Language"

    # --- Apply Tab Headers ---
    if ($localeData.ui.tabs) {
        $tabHeaders = @("Install", "Tweaks", "Config", "Updates")
        for ($i = 0; $i -lt $tabHeaders.Count; $i++) {
            $tabName = "WPFTab$($i + 1)"
            $originalHeader = $tabHeaders[$i]
            if ($localeData.ui.tabs.$originalHeader) {
                $tab = $sync.Form.FindName($tabName)
                if ($tab) {
                    $tab.Header = $localeData.ui.tabs.$originalHeader
                }
            }
        }
    }

    # --- Apply Navigation Button Headers ---
    if ($localeData.ui.navButtons) {
        $localeData.ui.navButtons.PSObject.Properties | ForEach-Object {
            $btnName = $_.Name
            $btnText = $_.Value
            if ($sync[$btnName]) {
                $sync[$btnName].Content = $btnText
            }
        }
    }

    # --- Apply Menu Item Headers ---
    if ($localeData.ui.menus) {
        $localeData.ui.menus.PSObject.Properties | ForEach-Object {
            $menuName = $_.Name
            $menuText = $_.Value
            $elem = $sync[$menuName]
            if ($elem) {
                Write-Debug "Localizing MenuItem: $menuName to $menuText"

                # Determine language code for specific menu items to apply flags
                $langCode = switch ($menuName) {
                    "EnglishLanguageMenuItem" { "en-US" }
                    "FrenchLanguageMenuItem" { "fr-FR" }
                    "SpanishLanguageMenuItem" { "es-ES" }
                    "GermanLanguageMenuItem" { "de-DE" }
                    "ItalianLanguageMenuItem" { "it-IT" }
                    "PortugueseLanguageMenuItem" { "pt-PT" }
                    "PolishLanguageMenuItem" { "pl-PL" }
                    "DutchLanguageMenuItem" { "nl-NL" }
                    "RomanianLanguageMenuItem" { "ro-RO" }
                    "SwedishLanguageMenuItem" { "sv-SE" }
                    "CzechLanguageMenuItem" { "cs-CZ" }
                    Default { $null }
                }

                if ($langCode) {
                    # Create a StackPanel with Flag and Text for the Header (more reliable than .Icon)
                    $sp = New-Object System.Windows.Controls.StackPanel
                    $sp.Orientation = "Horizontal"

                    $flag = Get-WinUtilFlagIcon -Language $langCode
                    if ($flag) {
                        $flag.Margin = "0,0,10,0"
                        $flag.VerticalAlignment = "Center"
                        $sp.Children.Add($flag) | Out-Null
                    }

                    $txt = New-Object System.Windows.Controls.TextBlock
                    $txt.Text = $menuText
                    $txt.VerticalAlignment = "Center"
                    $txt.Foreground = $elem.Foreground # Keep original color
                    $sp.Children.Add($txt) | Out-Null

                    $elem.Header = $sp
                }
                else {
                    $elem.Header = $menuText
                }
            }
        }
    }

    # --- Apply Tooltips ---
    if ($localeData.ui.tooltips) {
        $localeData.ui.tooltips.PSObject.Properties | ForEach-Object {
            $elemName = $_.Name
            $tooltipText = $_.Value
            $elem = $sync[$elemName]
            if ($elem) {
                # Some elements have simple ToolTip strings, others have ToolTip objects
                if ($elem.ToolTip -is [System.Windows.Controls.ToolTip]) {
                    $elem.ToolTip.Content = $tooltipText
                }
                else {
                    $elem.ToolTip = $tooltipText
                }
            }
        }
    }

    # --- Apply Button Content ---
    if ($localeData.ui.buttons) {
        $localeData.ui.buttons.PSObject.Properties | ForEach-Object {
            $btnName = $_.Name
            $btnText = $_.Value
            if ($sync[$btnName]) {
                $sync[$btnName].Content = $btnText
            }
        }
    }

    # --- Apply Labels ---
    if ($localeData.ui.labels) {
        # RecommendedSelections label - find by traversing the Tweaks tab
        # FontScaling, Small, Large labels are inside the FontScalingPopup
        $fontScalingPopup = $sync.Form.FindName("FontScalingPopup")
        if ($fontScalingPopup -and $localeData.ui.labels.FontScaling) {
            $border = $fontScalingPopup.Child
            if ($border) {
                $stackPanel = $border.Child
                if ($stackPanel -and $stackPanel.Children.Count -gt 0) {
                    # First child is the "Font Scaling" TextBlock
                    $stackPanel.Children[0].Text = $localeData.ui.labels.FontScaling
                    # Second is separator, third is horizontal stack with Small/Large
                    if ($stackPanel.Children.Count -gt 2) {
                        $hStack = $stackPanel.Children[2]
                        if ($hStack -is [System.Windows.Controls.StackPanel]) {
                            # First child = "Small", last = "Large"
                            if ($hStack.Children.Count -ge 3) {
                                $hStack.Children[0].Text = $localeData.ui.labels.Small
                                $hStack.Children[2].Text = $localeData.ui.labels.Large
                            }
                        }
                    }
                }
            }
        }
    }

    # --- Apply Updates Tab Content ---
    if ($localeData.ui.updates) {
        # Update button text
        @("WPFUpdatesdefault", "WPFUpdatessecurity", "WPFUpdatesdisable") | ForEach-Object {
            if ($sync[$_] -and $localeData.ui.updates.$_) {
                $sync[$_].Content = $localeData.ui.updates.$_
            }
        }
    }

    # --- Apply Tweak Content and Descriptions ---
    if ($localeData.config.tweaks) {
        $localeData.config.tweaks.PSObject.Properties | ForEach-Object {
            $tweakName = $_.Name
            $tweakData = $_.Value
            # Check for Label first (for Toggles and ComboBoxes)
            if ($sync[$tweakName + "Label"]) {
                if ($tweakData.Content) {
                    $sync[$tweakName + "Label"].Content = $tweakData.Content
                }
                if ($tweakData.Description) {
                    $sync[$tweakName + "Label"].ToolTip = $tweakData.Description
                }
            }
            # Fallback to standard control check
            elseif ($sync[$tweakName]) {
                if ($tweakData.Content) {
                    try {
                        if ($sync[$tweakName] -is [System.Windows.Controls.ContentControl] -or $null -ne $sync[$tweakName].Content) {
                            $sync[$tweakName].Content = $tweakData.Content
                        }
                    }
                    catch {
                        Write-Debug "Could not set Content for $tweakName"
                    }
                }
                if ($tweakData.Description) {
                    try {
                        if ($sync[$tweakName].ToolTip -is [System.Windows.Controls.ToolTip]) {
                            $sync[$tweakName].ToolTip.Content = $tweakData.Description
                        }
                        else {
                            $sync[$tweakName].ToolTip = $tweakData.Description
                        }
                    }
                    catch {
                        Write-Debug "Could not set ToolTip for $tweakName"
                    }
                }
            }
        }
    }

    # --- Apply Feature Content and Descriptions ---
    if ($localeData.config.features) {
        $localeData.config.features.PSObject.Properties | ForEach-Object {
            $featName = $_.Name
            $featData = $_.Value

            # Check for Label first
            if ($sync[$featName + "Label"]) {
                if ($featData.Content) {
                    $sync[$featName + "Label"].Content = $featData.Content
                }
                if ($featData.Description) {
                    $sync[$featName + "Label"].ToolTip = $featData.Description
                }
            }
            # Fallback to standard control check
            elseif ($sync[$featName]) {
                if ($featData.Content) {
                    try {
                        if ($sync[$featName] -is [System.Windows.Controls.ContentControl] -or $null -ne $sync[$featName].Content) {
                            $sync[$featName].Content = $featData.Content
                        }
                    }
                    catch { Write-Debug "Error setting Content for $featName" }
                }
                if ($featData.Description) {
                    try {
                        if ($sync[$featName].ToolTip -is [System.Windows.Controls.ToolTip]) {
                            $sync[$featName].ToolTip.Content = $featData.Description
                        }
                        else {
                            $sync[$featName].ToolTip = $featData.Description
                        }
                    }
                    catch { Write-Debug "Error setting ToolTip for $featName" }
                }
            }
        }
    }

    # --- Apply App Navigation Content and Descriptions ---
    if ($localeData.config.appnavigation) {
        $localeData.config.appnavigation.PSObject.Properties | ForEach-Object {
            $navName = $_.Name
            $navData = $_.Value
            # Check for Label first (e.g. for RadioButtons if they have matching labels)
            if ($sync[$navName + "Label"]) {
                if ($navData.Content) {
                    $sync[$navName + "Label"].Content = $navData.Content
                }
                if ($navData.Description) {
                    $sync[$navName + "Label"].ToolTip = $navData.Description
                }
            }
            # Fallback to standard control check
            elseif ($sync[$navName]) {
                if ($navData.Content) {
                    try {
                        if ($sync[$navName] -is [System.Windows.Controls.ContentControl] -or $null -ne $sync[$navName].Content) {
                            $sync[$navName].Content = $navData.Content
                        }
                    }
                    catch { Write-Debug "Error setting Content for $navName" }
                }
                if ($navData.Description) {
                    try {
                        if ($sync[$navName].ToolTip -is [System.Windows.Controls.ToolTip]) {
                            $sync[$navName].ToolTip.Content = $navData.Description
                        }
                        else {
                            $sync[$navName].ToolTip = $navData.Description
                        }
                    }
                    catch { Write-Debug "Error setting ToolTip for $navName" }
                }
            }
        }
    }

    # --- Apply Specific Named Elements (Updates & Notes) ---
    $updates = $localeData.ui.updates
    if ($updates) {
        if ($sync.UpdateDefaultTitle) { $sync.UpdateDefaultTitle.Text = $updates.DefaultTitle }
        if ($sync.UpdateDefaultLine1) { $sync.UpdateDefaultLine1.Text = $updates.DefaultLine1 }
        if ($sync.UpdateDefaultLine2) { $sync.UpdateDefaultLine2.Text = $updates.DefaultLine2 }
        if ($sync.UpdateDefaultNote) { $sync.UpdateDefaultNote.Text = $updates.DefaultNote }

        if ($sync.UpdateSecurityTitle) { $sync.UpdateSecurityTitle.Text = $updates.SecurityTitle }
        if ($sync.UpdateSecurityLine1) { $sync.UpdateSecurityLine1.Text = $updates.SecurityLine1 }
        if ($sync.UpdateSecurityLine2) { $sync.UpdateSecurityLine2.Text = $updates.SecurityLine2 }
        if ($sync.UpdateSecurityFeatureTitle) { $sync.UpdateSecurityFeatureTitle.Text = $updates.SecurityFeatureUpdates }
        if ($sync.UpdateSecurityFeatureText) { $sync.UpdateSecurityFeatureText.Text = $updates.SecurityFeatureDesc }
        if ($sync.UpdateSecuritySecurityTitle) { $sync.UpdateSecuritySecurityTitle.Text = $updates.SecuritySecurityUpdates }
        if ($sync.UpdateSecuritySecurityText) { $sync.UpdateSecuritySecurityText.Text = $updates.SecuritySecurityDesc }
        if ($sync.UpdateSecurityNote) { $sync.UpdateSecurityNote.Text = $updates.SecurityNote }

        if ($sync.UpdateDisableTitle) { $sync.UpdateDisableTitle.Text = $updates.DisableTitle }
        if ($sync.UpdateDisableLine1) { $sync.UpdateDisableLine1.Text = $updates.DisableLine1 }
        if ($sync.UpdateDisableLine2) { $sync.UpdateDisableLine2.Text = $updates.DisableLine2 }
        if ($sync.UpdateDisableLine3) { $sync.UpdateDisableLine3.Text = $updates.DisableLine3 }
        if ($sync.UpdateDisableNote) { $sync.UpdateDisableNote.Text = $updates.DisableNote }
    }

    if ($localeData.ui.textblocks.TweaksNote) {
        if ($sync.TweaksNoteBlock) { $sync.TweaksNoteBlock.Text = $localeData.ui.textblocks.TweaksNote }
    }

    # --- Apply Category Labels ---
    if ($localeData.config.categories) {
        # Categories are stored as Labels in $sync with keys like "category_name"
        # They are created by Invoke-WPFUIElements with the raw category name
        $localeData.config.categories.PSObject.Properties | ForEach-Object {
            $originalCat = $_.Name
            $translatedCat = $_.Value
            if ($sync[$originalCat] -and $sync[$originalCat] -is [System.Windows.Controls.Label]) {
                $sync[$originalCat].Content = $translatedCat
            }
        }
    }

    Write-Debug "Localization applied: $Language"
}

function Get-WinUtilLocalizedString {
    <#
    .SYNOPSIS
        Returns a localized string by key path, with English fallback.
    .PARAMETER Key
        Dot-separated key path (e.g., "ui.buttons.WPFstandard").
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $language = if ($sync.currentLanguage) { $sync.currentLanguage } else { "en-US" }
    $localeData = $sync.configs.locales[$language]

    if (-not $localeData) {
        $localeData = $sync.configs.locales["en-US"]
    }

    if (-not $localeData) {
        return $null
    }

    # Navigate the dot-separated path
    $parts = $Key.Split('.')
    $current = $localeData
    foreach ($part in $parts) {
        if ($current.PSObject.Properties[$part]) {
            $current = $current.$part
        }
        else {
            # Fallback to English
            $enData = $sync.configs.locales["en-US"]
            if ($enData) {
                $current = $enData
                foreach ($p in $parts) {
                    if ($current.PSObject.Properties[$p]) {
                        $current = $current.$p
                    }
                    else {
                        return $null
                    }
                }
                return $current
            }
            return $null
        }
    }
    return $current
}
