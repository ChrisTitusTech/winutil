function Invoke-WinUtilLanguageChange {
    <#
    .SYNOPSIS
        Changes the language of the WinUtil user interface.

    .DESCRIPTION
        Updates the labels, headers, tooltips, and buttons in the WinUtil UI
        based on the translations configured in $sync.configs.languages.

    .PARAMETER Language
        The language code to apply ('en' or 'es'). Defaults to 'en'.
    #>
    param (
        [ValidateSet("en", "es")]
        [string]$Language = "en"
    )

    if (-not $sync.configs.languages) {
        return
    }

    $strings = $sync.configs.languages.$Language
    if (-not $strings) {
        return
    }

    $sync.preferences.language = $Language

    # 1. Navigation Tabs
    if ($sync.WPFTab1BT -and $sync.WPFTab1BT.Content -is [System.Windows.Controls.TextBlock]) {
        $tb = $sync.WPFTab1BT.Content
        $tb.Inlines.Clear()
        if ($strings.Tab_Install_Prefix) {
            $null = $tb.Inlines.Add([System.Windows.Documents.Run]::new($strings.Tab_Install_Prefix))
        }
        $null = $tb.Inlines.Add([System.Windows.Documents.Underline]::new([System.Windows.Documents.Run]::new($strings.Tab_Install_Underline)))
        $null = $tb.Inlines.Add([System.Windows.Documents.Run]::new($strings.Tab_Install_Rest))
    }
    if ($sync.WPFTab2BT -and $sync.WPFTab2BT.Content -is [System.Windows.Controls.TextBlock]) {
        $tb = $sync.WPFTab2BT.Content
        $tb.Inlines.Clear()
        if ($strings.Tab_Tweaks_Prefix) {
            $null = $tb.Inlines.Add([System.Windows.Documents.Run]::new($strings.Tab_Tweaks_Prefix))
        }
        $null = $tb.Inlines.Add([System.Windows.Documents.Underline]::new([System.Windows.Documents.Run]::new($strings.Tab_Tweaks_Underline)))
        $null = $tb.Inlines.Add([System.Windows.Documents.Run]::new($strings.Tab_Tweaks_Rest))
    }
    if ($sync.WPFTab3BT -and $sync.WPFTab3BT.Content -is [System.Windows.Controls.TextBlock]) {
        $tb = $sync.WPFTab3BT.Content
        $tb.Inlines.Clear()
        if ($strings.Tab_Config_Prefix) {
            $null = $tb.Inlines.Add([System.Windows.Documents.Run]::new($strings.Tab_Config_Prefix))
        }
        $null = $tb.Inlines.Add([System.Windows.Documents.Underline]::new([System.Windows.Documents.Run]::new($strings.Tab_Config_Underline)))
        $null = $tb.Inlines.Add([System.Windows.Documents.Run]::new($strings.Tab_Config_Rest))
    }
    if ($sync.WPFTab4BT -and $sync.WPFTab4BT.Content -is [System.Windows.Controls.TextBlock]) {
        $tb = $sync.WPFTab4BT.Content
        $tb.Inlines.Clear()
        if ($strings.Tab_Updates_Prefix) {
            $null = $tb.Inlines.Add([System.Windows.Documents.Run]::new($strings.Tab_Updates_Prefix))
        }
        $null = $tb.Inlines.Add([System.Windows.Documents.Underline]::new([System.Windows.Documents.Run]::new($strings.Tab_Updates_Underline)))
        $null = $tb.Inlines.Add([System.Windows.Documents.Run]::new($strings.Tab_Updates_Rest))
    }
    if ($sync.WPFTab5BT -and $sync.WPFTab5BT.Content -is [System.Windows.Controls.TextBlock]) {
        $tb = $sync.WPFTab5BT.Content
        $tb.Inlines.Clear()
        if ($strings.Tab_Win11Creator_Prefix) {
            $null = $tb.Inlines.Add([System.Windows.Documents.Run]::new($strings.Tab_Win11Creator_Prefix))
        }
        $null = $tb.Inlines.Add([System.Windows.Documents.Underline]::new([System.Windows.Documents.Run]::new($strings.Tab_Win11Creator_Underline)))
        $null = $tb.Inlines.Add([System.Windows.Documents.Run]::new($strings.Tab_Win11Creator_Rest))
    }

    # 2. Settings Menu Items
    if ($sync.EnglishLanguageMenuItem) {
        $sync.EnglishLanguageMenuItem.Header = if ($Language -eq "en") { "$($strings.Language_English) (Active)" } else { $strings.Language_English }
    }
    if ($sync.SpanishLanguageMenuItem) {
        $sync.SpanishLanguageMenuItem.Header = if ($Language -eq "es") { "$($strings.Language_Spanish) (Activo)" } else { $strings.Language_Spanish }
    }
    if ($sync.ImportMenuItem) {
        $sync.ImportMenuItem.Header = $strings.Menu_Import
        if ($sync.ImportMenuItem.ToolTip) { $sync.ImportMenuItem.ToolTip.Content = $strings.Menu_Import_ToolTip }
    }
    if ($sync.ExportMenuItem) {
        $sync.ExportMenuItem.Header = $strings.Menu_Export
        if ($sync.ExportMenuItem.ToolTip) { $sync.ExportMenuItem.ToolTip.Content = $strings.Menu_Export_ToolTip }
    }
    if ($sync.ExportEnvironmentReportMenuItem) {
        $sync.ExportEnvironmentReportMenuItem.Header = $strings.Menu_ExportEnvironmentReport
        if ($sync.ExportEnvironmentReportMenuItem.ToolTip) { $sync.ExportEnvironmentReportMenuItem.ToolTip.Content = $strings.Menu_ExportEnvironmentReport_ToolTip }
    }
    if ($sync.AboutMenuItem) { $sync.AboutMenuItem.Header = $strings.Menu_About }
    if ($sync.DocumentationMenuItem) { $sync.DocumentationMenuItem.Header = $strings.Menu_Documentation }
    if ($sync.SponsorMenuItem) { $sync.SponsorMenuItem.Header = $strings.Menu_Sponsors }

    # 3. Toolbars & Controls ToolTips
    if ($sync.ThemeButton) { $sync.ThemeButton.ToolTip = $strings.Theme_ToolTip }
    if ($sync.AutoThemeMenuItem) {
        $sync.AutoThemeMenuItem.Header = $strings.Theme_Auto
        if ($sync.AutoThemeMenuItem.ToolTip) { $sync.AutoThemeMenuItem.ToolTip.Content = $strings.Theme_Auto_ToolTip }
    }
    if ($sync.DarkThemeMenuItem) {
        $sync.DarkThemeMenuItem.Header = $strings.Theme_Dark
        if ($sync.DarkThemeMenuItem.ToolTip) { $sync.DarkThemeMenuItem.ToolTip.Content = $strings.Theme_Dark_ToolTip }
    }
    if ($sync.LightThemeMenuItem) {
        $sync.LightThemeMenuItem.Header = $strings.Theme_Light
        if ($sync.LightThemeMenuItem.ToolTip) { $sync.LightThemeMenuItem.ToolTip.Content = $strings.Theme_Light_ToolTip }
    }
    if ($sync.FontScalingButton) { $sync.FontScalingButton.ToolTip = $strings.FontScaling_ToolTip }
    if ($sync.FontScalingTitleTextBlock) { $sync.FontScalingTitleTextBlock.Text = $strings.FontScaling_Title }
    if ($sync.FontScalingSmallTextBlock) { $sync.FontScalingSmallTextBlock.Text = $strings.FontScaling_Small }
    if ($sync.FontScalingLargeTextBlock) { $sync.FontScalingLargeTextBlock.Text = $strings.FontScaling_Large }
    if ($sync.FontScalingResetButton) { $sync.FontScalingResetButton.Content = $strings.FontScaling_Reset }
    if ($sync.FontScalingApplyButton) { $sync.FontScalingApplyButton.Content = $strings.FontScaling_Apply }
    if ($sync.SettingsButton) { $sync.SettingsButton.ToolTip = $strings.Settings_ToolTip }
    if ($sync.WPFMinimizeButton) { $sync.WPFMinimizeButton.ToolTip = $strings.Minimize_ToolTip }
    if ($sync.WPFCloseButton) { $sync.WPFCloseButton.ToolTip = $strings.Close_ToolTip }
    if ($sync.SearchBar) { $sync.SearchBar.ToolTip = $strings.SearchBar_ToolTip }

    # 4. Install Tab Category Filter Chips
    if ($sync.WPFSearchChipAll) { $sync.WPFSearchChipAll.Content = $strings.Chip_All }
    if ($sync.WPFSearchChipBrowsers) { $sync.WPFSearchChipBrowsers.Content = $strings.Chip_Browsers }
    if ($sync.WPFSearchChipCommunications) { $sync.WPFSearchChipCommunications.Content = $strings.Chip_Communications }
    if ($sync.WPFSearchChipDevelopment) { $sync.WPFSearchChipDevelopment.Content = $strings.Chip_Development }
    if ($sync.WPFSearchChipDocument) { $sync.WPFSearchChipDocument.Content = $strings.Chip_Document }
    if ($sync.WPFSearchChipGames) { $sync.WPFSearchChipGames.Content = $strings.Chip_Games }
    if ($sync.WPFSearchChipMicrosoftTools) { $sync.WPFSearchChipMicrosoftTools.Content = $strings.Chip_MicrosoftTools }
    if ($sync.WPFSearchChipMultimediaTools) { $sync.WPFSearchChipMultimediaTools.Content = $strings.Chip_MultimediaTools }
    if ($sync.WPFSearchChipProTools) { $sync.WPFSearchChipProTools.Content = $strings.Chip_ProTools }
    if ($sync.WPFSearchChipSelfhostedTools) { $sync.WPFSearchChipSelfhostedTools.Content = $strings.Chip_SelfhostedTools }
    if ($sync.WPFSearchChipUtilities) { $sync.WPFSearchChipUtilities.Content = $strings.Chip_Utilities }

    # 5. Install Tab Actions & Navigation Buttons
    if ($sync.WPFInstall) {
        $sync.WPFInstall.Content = $strings.Nav_Install
        $sync.WPFInstall.ToolTip = $strings.Nav_Install_Desc
    }
    if ($sync.WPFUninstall) {
        $sync.WPFUninstall.Content = $strings.Nav_Uninstall
        $sync.WPFUninstall.ToolTip = $strings.Nav_Uninstall_Desc
    }
    if ($sync.WPFInstallUpgrade) {
        $sync.WPFInstallUpgrade.Content = $strings.Nav_UpgradeAll
        $sync.WPFInstallUpgrade.ToolTip = $strings.Nav_UpgradeAll_Desc
    }
    if ($sync.WPFCollapseAllCategories) {
        $sync.WPFCollapseAllCategories.Content = $strings.Nav_CollapseAll
        $sync.WPFCollapseAllCategories.ToolTip = $strings.Nav_CollapseAll_Desc
    }
    if ($sync.WPFExpandAllCategories) {
        $sync.WPFExpandAllCategories.Content = $strings.Nav_ExpandAll
        $sync.WPFExpandAllCategories.ToolTip = $strings.Nav_ExpandAll_Desc
    }
    if ($sync.WPFClearInstallSelection) {
        $sync.WPFClearInstallSelection.Content = $strings.Nav_ClearSelection
        $sync.WPFClearInstallSelection.ToolTip = $strings.Nav_ClearSelection_Desc
    }
    if ($sync.WPFGetInstalled) {
        $sync.WPFGetInstalled.Content = $strings.Nav_ShowInstalled
        $sync.WPFGetInstalled.ToolTip = $strings.Nav_ShowInstalled_Desc
    }

    # 6. Tweaks Tab Buttons & Static Text
    if ($sync.WPFstandard) { $sync.WPFstandard.Content = $strings.Tweaks_Standard }
    if ($sync.WPFminimal) { $sync.WPFminimal.Content = $strings.Tweaks_Minimal }
    if ($sync.WPFAdvanced) { $sync.WPFAdvanced.Content = $strings.Tweaks_Advanced }
    if ($sync.WPFClearTweaksSelection) { $sync.WPFClearTweaksSelection.Content = $strings.Tweaks_Clear }
    if ($sync.WPFGetInstalledTweaks) { $sync.WPFGetInstalledTweaks.Content = $strings.Tweaks_SelectInstalledTweaks }
    if ($sync.WPFAppxRemoval) { $sync.WPFAppxRemoval.Content = $strings.Tweaks_AppXRemoval }
    if ($sync.WPFTweaksbutton) { $sync.WPFTweaksbutton.Content = $strings.Tweaks_RunTweaks }
    if ($sync.WPFUndoall) { $sync.WPFUndoall.Content = $strings.Tweaks_UndoSelectedTweaks }
    if ($sync.WPFTweaksRecommendedLabel) { $sync.WPFTweaksRecommendedLabel.Content = $strings.Tweaks_RecommendedSelections }
    if ($sync.WPFTweaksNoteTextBlock) { $sync.WPFTweaksNoteTextBlock.Text = $strings.Tweaks_Note }

    # 7. Updates Tab Buttons & Content
    if ($sync.WPFUpdatessecurity) { $sync.WPFUpdatessecurity.Content = $strings.Updates_ApplyRecommended }
    if ($sync.WPFUpdatesdefault) { $sync.WPFUpdatesdefault.Content = $strings.Updates_RestoreDefaults }
    if ($sync.WPFUpdatesdisable) { $sync.WPFUpdatesdisable.Content = $strings.Updates_DisableUpdates }
    if ($sync.WPFUpdatesTitle) { $sync.WPFUpdatesTitle.Text = $strings.Updates_Title }
    if ($sync.WPFUpdatesDescription) { $sync.WPFUpdatesDescription.Text = $strings.Updates_Description }
    if ($sync.WPFUpdatesRecommendedTitle) { $sync.WPFUpdatesRecommendedTitle.Text = $strings.Updates_Recommended }
    if ($sync.WPFUpdatesRecommendedSubtitle) { $sync.WPFUpdatesRecommendedSubtitle.Text = $strings.Updates_Recommended_Subtitle }
    if ($sync.WPFUpdatesRecommendedBullet1) { $sync.WPFUpdatesRecommendedBullet1.Text = $strings.Updates_Recommended_Bullet1 }
    if ($sync.WPFUpdatesRecommendedBullet2) { $sync.WPFUpdatesRecommendedBullet2.Text = $strings.Updates_Recommended_Bullet2 }
    if ($sync.WPFUpdatesRecommendedBullet3) { $sync.WPFUpdatesRecommendedBullet3.Text = $strings.Updates_Recommended_Bullet3 }
    if ($sync.WPFUpdatesRecommendedBullet4) { $sync.WPFUpdatesRecommendedBullet4.Text = $strings.Updates_Recommended_Bullet4 }
    if ($sync.WPFUpdatesRecommendedEdition) { $sync.WPFUpdatesRecommendedEdition.Text = $strings.Updates_RecommendedEdition }
    if ($sync.WPFUpdatesDefaultTitle) { $sync.WPFUpdatesDefaultTitle.Text = $strings.Updates_WindowsDefault }
    if ($sync.WPFUpdatesDefaultSubtitle) { $sync.WPFUpdatesDefaultSubtitle.Text = $strings.Updates_WindowsDefault_Subtitle }
    if ($sync.WPFUpdatesDefaultBullet1) { $sync.WPFUpdatesDefaultBullet1.Text = $strings.Updates_WindowsDefault_Bullet1 }
    if ($sync.WPFUpdatesDefaultBullet2) { $sync.WPFUpdatesDefaultBullet2.Text = $strings.Updates_WindowsDefault_Bullet2 }
    if ($sync.WPFUpdatesDefaultBullet3) { $sync.WPFUpdatesDefaultBullet3.Text = $strings.Updates_WindowsDefault_Bullet3 }
    if ($sync.WPFUpdatesDefaultUndoHint) { $sync.WPFUpdatesDefaultUndoHint.Text = $strings.Updates_WindowsDefault_UndoHint }
    if ($sync.WPFUpdatesDisableTitle) { $sync.WPFUpdatesDisableTitle.Text = $strings.Updates_DisableUpdates }
    if ($sync.WPFUpdatesDisableSubtitle) { $sync.WPFUpdatesDisableSubtitle.Text = $strings.Updates_DisableUpdates_Subtitle }
    if ($sync.WPFUpdatesDisableBullet1) { $sync.WPFUpdatesDisableBullet1.Text = $strings.Updates_DisableUpdates_Bullet1 }
    if ($sync.WPFUpdatesDisableBullet2) { $sync.WPFUpdatesDisableBullet2.Text = $strings.Updates_DisableUpdates_Bullet2 }
    if ($sync.WPFUpdatesDisableBullet3) { $sync.WPFUpdatesDisableBullet3.Text = $strings.Updates_DisableUpdates_Bullet3 }
    if ($sync.WPFUpdatesDisableWarning) { $sync.WPFUpdatesDisableWarning.Text = $strings.Updates_DisableUpdates_Warning }
    if ($sync.WPFUpdatesSystemWide) { $sync.WPFUpdatesSystemWide.Text = $strings.Updates_SystemWide }

    # 8. Win11 Creator Tab Buttons & Content
    if ($sync.WPFWin11ISOSelectSection) { $sync.WPFWin11ISOSelectSection.Header = $strings.Win11ISO_Step1 }
    if ($sync.WPFWin11ISOModifySection) { $sync.WPFWin11ISOModifySection.Header = $strings.Win11ISO_Step2 }
    if ($sync.WPFWin11ISOOutputSection) { $sync.WPFWin11ISOOutputSection.Header = $strings.Win11ISO_Step3 }
    if ($sync.WPFWin11ISOStep1Title) { $sync.WPFWin11ISOStep1Title.Text = $strings.Win11ISO_SelectISO }
    if ($sync.WPFWin11ISOStep1Subtitle) { $sync.WPFWin11ISOStep1Subtitle.Text = $strings.Win11ISO_SelectISOSubtitle }
    if ($sync.WPFWin11ISOFileLabel) { $sync.WPFWin11ISOFileLabel.Text = $strings.Win11ISO_ISOFile }
    if ($sync.WPFWin11ISOBrowseButton) { $sync.WPFWin11ISOBrowseButton.Content = $strings.Win11ISO_Browse }
    if ($sync.WPFWin11ISOMountButton) { $sync.WPFWin11ISOMountButton.Content = $strings.Win11ISO_MountVerify }
    if ($sync.WPFWin11ISOMicrosoftWarningRun) { $sync.WPFWin11ISOMicrosoftWarningRun.Text = $strings.Win11ISO_OfficialISO }
    if ($sync.WPFWin11ISOUnofficialWarning) { $sync.WPFWin11ISOUnofficialWarning.Text = $strings.Win11ISO_UnofficialWarning }
    if ($sync.WPFWin11ISODownloadPageHint) { $sync.WPFWin11ISODownloadPageHint.Text = $strings.Win11ISO_DownloadPageHint }
    if ($sync.WPFWin11ISODownloadLink) { $sync.WPFWin11ISODownloadLink.Content = $strings.Win11ISO_OpenDownloadPage }
    if ($sync.WPFWin11ISOStep2Title) { $sync.WPFWin11ISOStep2Title.Text = $strings.Win11ISO_ModifyImage }
    if ($sync.WPFWin11ISOStep2Subtitle) { $sync.WPFWin11ISOStep2Subtitle.Text = $strings.Win11ISO_ModifyImageSubtitle }
    if ($sync.WPFWin11ISOMountedAtLabel) { $sync.WPFWin11ISOMountedAtLabel.Text = $strings.Win11ISO_MountedAt }
    if ($sync.WPFWin11ISOImageFileLabel) { $sync.WPFWin11ISOImageFileLabel.Text = $strings.Win11ISO_ImageFile }
    if ($sync.WPFWin11ISOEditionLabel) { $sync.WPFWin11ISOEditionLabel.Text = $strings.Win11ISO_Edition }
    if ($sync.WPFWin11ISOInjectDrivers) {
        $sync.WPFWin11ISOInjectDrivers.Content = $strings.Win11ISO_InjectDrivers
        $sync.WPFWin11ISOInjectDrivers.ToolTip = $strings.Win11ISO_InjectDrivers_ToolTip
    }
    if ($sync.WPFWin11ISOModifyButton) { $sync.WPFWin11ISOModifyButton.Content = $strings.Win11ISO_Title }
    if ($sync.WPFWin11ISODoesHeader) { $sync.WPFWin11ISODoesHeader.Text = $strings.Win11ISO_WhatThisDoes }
    if ($sync.WPFWin11ISODoesRemoveApps) { $sync.WPFWin11ISODoesRemoveApps.Text = $strings.Win11ISO_RemoveApps }
    if ($sync.WPFWin11ISODoesBypassTPM) { $sync.WPFWin11ISODoesBypassTPM.Text = $strings.Win11ISO_BypassTPM }
    if ($sync.WPFWin11ISODoesSkipMS) { $sync.WPFWin11ISODoesSkipMS.Text = $strings.Win11ISO_SkipMSAccount }
    if ($sync.WPFWin11ISODoesTelemetry) { $sync.WPFWin11ISODoesTelemetry.Text = $strings.Win11ISO_TurnOffTelemetry }
    if ($sync.WPFWin11ISODoesPinEdition) { $sync.WPFWin11ISODoesPinEdition.Text = $strings.Win11ISO_PinEdition }
    if ($sync.WPFWin11ISOStep3Title) { $sync.WPFWin11ISOStep3Title.Text = $strings.Win11ISO_ImageReady }
    if ($sync.WPFWin11ISOStep3Subtitle) { $sync.WPFWin11ISOStep3Subtitle.Text = $strings.Win11ISO_ImageReadySubtitle }
    if ($sync.WPFWin11ISOChooseISOButton) { $sync.WPFWin11ISOChooseISOButton.Content = $strings.Win11ISO_SaveISO }
    if ($sync.WPFWin11ISOChooseUSBButton) { $sync.WPFWin11ISOChooseUSBButton.Content = $strings.Win11ISO_WriteToDrive }
    if ($sync.WPFWin11ISOUSBEraseWarningRun) { $sync.WPFWin11ISOUSBEraseWarningRun.Text = $strings.Win11ISO_USBEraseWarning }
    if ($sync.WPFWin11ISOUSBLabel) { $sync.WPFWin11ISOUSBLabel.Text = $strings.Win11ISO_USBDrive }
    if ($sync.WPFWin11ISORefreshUSBButton) { $sync.WPFWin11ISORefreshUSBButton.Content = $strings.Win11ISO_Refresh }
    if ($sync.WPFWin11ISOWriteUSBButton) { $sync.WPFWin11ISOWriteUSBButton.Content = $strings.Win11ISO_EraseWrite }
    if ($sync.WPFWin11ISODoneSubtitle) { $sync.WPFWin11ISODoneSubtitle.Text = $strings.Win11ISO_DoneHint }
    if ($sync.WPFWin11ISOCleanResetButton) { $sync.WPFWin11ISOCleanResetButton.Content = $strings.Win11ISO_StartOver }
    if ($sync.WPFWin11ISOWorkingLabel) { $sync.WPFWin11ISOWorkingLabel.Text = $strings.Win11ISO_Working }
    if ($sync.WPFWin11ISOWorkingSubtitle) { $sync.WPFWin11ISOWorkingSubtitle.Text = $strings.Win11ISO_SeveralMinutes }
    if ($sync.WPFWin11ISOStatusLogLabel) { $sync.WPFWin11ISOStatusLogLabel.Text = $strings.Win11ISO_StatusLog }
    if ($sync.WPFWin11ISOBackButton) { $sync.WPFWin11ISOBackButton.ToolTip = $strings.Win11ISO_Back_ToolTip }
    if ($sync.WPFWin11ISOForwardButton) { $sync.WPFWin11ISOForwardButton.ToolTip = $strings.Win11ISO_Forward_ToolTip }
    if ($sync.WPFWin11ISOPath) {
        if ([string]::IsNullOrWhiteSpace($sync.WPFWin11ISOPath.Text) -or
            $sync.WPFWin11ISOPath.Text -eq "No ISO selected..." -or
            $sync.WPFWin11ISOPath.Text -eq "No se ha seleccionado ninguna ISO...") {
            $sync.WPFWin11ISOPath.Text = $strings.Win11ISO_NoISO
        }
    }
    if ($sync.WPFWin11ISOStatusLog) {
        if ([string]::IsNullOrWhiteSpace($sync.WPFWin11ISOStatusLog.Text) -or
            $sync.WPFWin11ISOStatusLog.Text -eq "Ready. Please select a Windows 11 ISO to begin." -or
            $sync.WPFWin11ISOStatusLog.Text -eq "Listo. Por favor selecciona una ISO de Windows 11 para comenzar.") {
            $sync.WPFWin11ISOStatusLog.Text = $strings.Win11ISO_Ready
        }
    }

    # 9. AppX Tab Buttons & Content
    if ($sync.WPFAppxSelectionsLabel) { $sync.WPFAppxSelectionsLabel.Content = $strings.AppX_Selections }
    if ($sync.WPFDefaultAppxSelection) { $sync.WPFDefaultAppxSelection.Content = $strings.AppX_Default }
    if ($sync.WPFGetInstalledAppx) { $sync.WPFGetInstalledAppx.Content = $strings.AppX_SelectInstalled }
    if ($sync.WPFSelectAllAppx) { $sync.WPFSelectAllAppx.Content = $strings.AppX_SelectAll }
    if ($sync.WPFClearAppxSelection) { $sync.WPFClearAppxSelection.Content = $strings.AppX_ClearSelection }
    if ($sync.WPFAppxNoteTextBlock) { $sync.WPFAppxNoteTextBlock.Text = $strings.AppX_Note }
    if ($sync.WPFBackToTweaks) { $sync.WPFBackToTweaks.Content = $strings.AppX_BackToTweaks }
    if ($sync.WPFInstallSelectedAppx) { $sync.WPFInstallSelectedAppx.Content = $strings.AppX_InstallSelected }
    if ($sync.WPFRemoveSelectedAppx) { $sync.WPFRemoveSelectedAppx.Content = $strings.AppX_RemoveSelected }

    # 10. Dynamic Categories in Tweaks, Config, and AppNavigation
    if ($strings.categories) {
        foreach ($prop in $strings.categories.PSObject.Properties) {
            $catKey = $prop.Name
            if ($sync.ContainsKey($catKey)) {
                $lbl = $sync[$catKey]
                if ($lbl -and $lbl -is [System.Windows.Controls.Label]) {
                    $lbl.Content = $prop.Value
                }
            }
        }
    }

    # Helper scriptblock to update a generated entry control (handles CheckBox, Toggle switch, ComboBox, Button, RadioButton)
    $updateEntryControl = {
        param($ctrl, $entryData, $entryName)
        if (-not $ctrl) { return }

        # Check if control is inside a container with a sibling Label (Toggle DockPanel or ComboBox StackPanel)
        $label = $null
        if ($ctrl.Parent -and ($ctrl.Parent -is [System.Windows.Controls.DockPanel] -or $ctrl.Parent -is [System.Windows.Controls.StackPanel])) {
            $label = @($ctrl.Parent.Children) | Where-Object { $_ -is [System.Windows.Controls.Label] } | Select-Object -First 1
        }

        if ($label) {
            if ($entryData.Content) {
                $label.Content = $entryData.Content
            }
            if ($entryData.Description) {
                $label.ToolTip = Get-WinUtilEntryToolTip -Description $entryData.Description -Key $entryName
            } else {
                $label.ToolTip = $null
            }
        } else {
            if ($entryData.Content -and ($ctrl.PSObject.Properties.Match('Content').Count -gt 0)) {
                $ctrl.Content = $entryData.Content
            }
            if ($entryData.Description) {
                $ctrl.ToolTip = Get-WinUtilEntryToolTip -Description $entryData.Description -Key $entryName
            } else {
                $ctrl.ToolTip = $null
            }
        }
    }

    # 11. Dynamic Tweaks (all 68 tweaks)
    if ($strings.tweaks) {
        foreach ($prop in $strings.tweaks.PSObject.Properties) {
            $tweakName = $prop.Name
            $tweakData = $prop.Value
            if ($sync.ContainsKey($tweakName)) {
                & $updateEntryControl $sync[$tweakName] $tweakData $tweakName
            }
        }
    }

    # 12. Dynamic Features (all 33 features)
    if ($strings.features) {
        foreach ($prop in $strings.features.PSObject.Properties) {
            $featName = $prop.Name
            $featData = $prop.Value
            if ($sync.ContainsKey($featName)) {
                & $updateEntryControl $sync[$featName] $featData $featName
            }
        }
    }
}
