#===========================================================================
# Tests - UI localization (en / ar)
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:localeScript = Join-Path $script:repoRoot "functions\private\Set-WinUtilLanguage.ps1"
    . $script:localeScript
    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilLanguageDirection.ps1")

    function Write-WinUtilLog { param($Level, $Component, $Message) }
}

Describe "Localization resources" {
    BeforeEach {
        $script:sync = @{
            Form = [pscustomobject]@{
                Resources = @{}
                Dispatcher = [pscustomobject]@{}
                FlowDirection = "LeftToRight"
            }
            preferences = @{ language = "en" }
            configs = @{
                locales = @{
                    en = [pscustomobject]@{ s_install = "Install"; s_language = "Language" }
                    ar = [pscustomobject]@{ s_install = "تثبيت"; s_language = "اللغة" }
                }
                languages = [pscustomobject]@{
                    en = [pscustomobject]@{ code = "en"; displayNameKey = "s_language_english"; flowDirection = "LeftToRight" }
                    ar = [pscustomobject]@{ code = "ar"; displayNameKey = "s_language_arabic"; flowDirection = "RightToLeft" }
                }
            }
        }
    }

    It "applies every key of the selected locale to window resources" {
        Set-WinUtilLanguage -Language "ar"

        $script:sync.Form.Resources["s_install"] | Should -Be "تثبيت"
        $script:sync.Form.Resources["s_language"] | Should -Be "اللغة"
        Get-WinUtilLanguage | Should -Be "ar"
    }

    It "switches the window to right-to-left for Arabic and back for English" {
        Set-WinUtilLanguage -Language "ar"
        $script:sync.Form.FlowDirection | Should -Be "RightToLeft"

        Set-WinUtilLanguage -Language "en"
        $script:sync.Form.FlowDirection | Should -Be "LeftToRight"
        $script:sync.Form.Resources["s_install"] | Should -Be "Install"
    }

    It "localizes WPFToggle-style tweak names via the Tweaks default prefix" {
        $ar = Get-Content (Join-Path $script:repoRoot "config\locales\ar.json") -Raw | ConvertFrom-Json
        $ar.PSObject.Properties['s_tweak_WPFToggleDetailedBSoD'].Value | Should -Be 'وضع الشاشة الزرقاء المُفصّل'
        $tab = Get-Content (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilTabContent.ps1") -Raw
        $tab | Should -Match "-DefaultPrefix 's_tweak_'"
        $render = Get-Content (Join-Path $script:repoRoot "functions\public\Invoke-WPFUIElements.ps1") -Raw
        $render | Should -Match '\$DefaultPrefix'
    }

    It "localizes Fixes, Remote Access and Legacy panels via the Config default prefix" {
        $ar = Get-Content (Join-Path $script:repoRoot "config\locales\ar.json") -Raw | ConvertFrom-Json
        $ar.PSObject.Properties['s_feature_WPFFixesNTPPool'].Value | Should -Be 'خادم NTP - تفعيل'
        $ar.PSObject.Properties['s_feature_WPFPanelControl'].Value | Should -Be 'لوحة التحكم'
        $ar.PSObject.Properties['s_feature_WPFWinUtilSSHServer'].Value | Should -Be 'خادم OpenSSH - تفعيل'
        $ar.PSObject.Properties['s_cat_remote_access'].Value | Should -Be 'الوصول عن بُعد'
        $tab = Get-Content (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilTabContent.ps1") -Raw
        $tab | Should -Match "-DefaultPrefix 's_feature_'"
    }

    It "keeps all locale files in sync" {
        $localeDir = Join-Path $script:repoRoot "config\locales"
        $en = Get-Content (Join-Path $localeDir "en.json") -Raw | ConvertFrom-Json
        $enKeys = @($en.PSObject.Properties.Name)
        foreach ($file in Get-ChildItem -Path $localeDir -Filter "*.json" -File) {
            $other = Get-Content $file.FullName -Raw | ConvertFrom-Json
            $otherKeys = @($other.PSObject.Properties.Name)
            @($enKeys | Where-Object { $_ -notin $otherKeys }) | Should -BeNullOrEmpty
            @($otherKeys | Where-Object { $_ -notin $enKeys }) | Should -BeNullOrEmpty
        }
        $ar = Get-Content (Join-Path $localeDir "ar.json") -Raw | ConvertFrom-Json
        $arKeys = @($ar.PSObject.Properties.Name)

        @($enKeys | Where-Object { $_ -notin $arKeys }) | Should -BeNullOrEmpty
        @($arKeys | Where-Object { $_ -notin $enKeys }) | Should -BeNullOrEmpty
        $enKeys.Count | Should -BeGreaterThan 100
    }

    It "re-renders the current wizard card when the language changes" {
        $source = Get-Content (Join-Path $script:repoRoot "functions\private\Set-WinUtilLanguage.ps1") -Raw
        $source | Should -Match 'Set-WinUtilGuideStep -Step'
        $source | Should -Match '\$sync\.UiMode -eq "Setup"'
    }

    It "rebuilds config-backed tabs when the language changes" {
        $source = Get-Content (Join-Path $script:repoRoot "functions\private\Set-WinUtilLanguage.ps1") -Raw
        $source | Should -Match 'InitializedTabs\[\$tab\] = \$false'
        $source | Should -Match 'Invoke-WPFTab \$clicked'
    }

    It "keeps help icons left-to-right in RTL" {
        $renderer = Get-Content (Join-Path $script:repoRoot "functions\public\Invoke-WPFUIElements.ps1") -Raw
        @([regex]::Matches($renderer, '\$textBlock\.FlowDirection = "LeftToRight"')).Count | Should -BeGreaterOrEqual 2
    }

    It "keeps advanced-mode app icons to the left of their names in RTL" {
        $source = Get-Content (Join-Path $script:repoRoot "functions\private\Initialize-InstallAppEntries.ps1") -Raw
        $source | Should -Match 'FlowDirection="LeftToRight"'
        $source | Should -Match '<StackPanel Orientation="Horizontal" VerticalAlignment="Center" FlowDirection="LeftToRight">'
    }

    It "keeps the top tab bar left-to-right in RTL" {
        $xaml = Get-Content (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw
        $tabNav = [regex]::Match($xaml, '<TabControl Name="WPFTabNav"[^>]*>').Value
        $tabNav | Should -Match 'FlowDirection="LeftToRight"'
    }

    It "localizes the Install tab Actions panel and flips it to the right in Arabic" {
        $en = Get-Content (Join-Path $script:repoRoot "config\locales\en.json") -Raw | ConvertFrom-Json
        $ar = Get-Content (Join-Path $script:repoRoot "config\locales\ar.json") -Raw | ConvertFrom-Json
        $ar.PSObject.Properties['s_appnav_WPFInstall'].Value | Should -Be 'تثبيت/ترقية التطبيقات'
        $ar.PSObject.Properties['s_appnav_cat__actions'].Value | Should -Be 'الإجراءات'
        $ar.PSObject.Properties['s_appnav_cat__selection'].Value | Should -Be 'التحديد'
        $ar.PSObject.Properties['s_appnav_WPFGetInstalled'].Value | Should -Be 'عرض التطبيقات المثبّتة'
        $source = Get-Content (Join-Path $script:repoRoot "functions\private\Set-WinUtilLanguage.ps1") -Raw
        $source | Should -Match 'WPFInstallContentGrid\.FlowDirection'
        $render = Get-Content (Join-Path $script:repoRoot "functions\public\Invoke-WPFUIElements.ps1") -Raw
        $render | Should -Match 'LocalePrefix'
        $ui = Get-Content (Join-Path $script:repoRoot "functions\public\Initialize-WPFUI.ps1") -Raw
        $ui | Should -Match "-LocalePrefix 's_appnav_'"
    }

    It "keeps the title-bar button container left-to-right in RTL" {
        $xaml = Get-Content (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw
        # The buttons container must explicitly pin LTR; otherwise RTL puts window buttons on the left.
        $match = [regex]::Match($xaml, '<!-- Buttons Container -->\s*<StackPanel[^>]*FlowDirection="LeftToRight"')
        $match.Success | Should -BeTrue
    }

    It "localizes tweak and feature labels from config" {
        $en = Get-Content (Join-Path $script:repoRoot "config\locales\en.json") -Raw | ConvertFrom-Json
        $ar = Get-Content (Join-Path $script:repoRoot "config\locales\ar.json") -Raw | ConvertFrom-Json
        $en.PSObject.Properties['s_tweak_Activity'].Value | Should -Be 'Activity History - Disable'
        $ar.PSObject.Properties['s_tweak_Activity'].Value | Should -Be 'سجل النشاط - تعطيل'
        $en.PSObject.Properties['s_cat_essential_tweaks'] | Should -Not -BeNull
        $ar.PSObject.Properties['s_cat_essential_tweaks'].Value | Should -Be 'تعديلات أساسية'
    }

    It "has no untranslated Arabic values except proper names and numerals" {
        $ar = Get-Content (Join-Path $script:repoRoot "config\locales\ar.json") -Raw -Encoding UTF8 | ConvertFrom-Json
        $allowed = @('s_100','s_win11iso','s_appx','s_win11_creator','s_language_english','s_summary_dns','s_appnav_ChocoRadioButton','s_appnav_WingetRadioButton')
        $untranslated = @($ar.PSObject.Properties |
            Where-Object { $_.Name -notin $allowed -and [string]$_.Value -notmatch '[\u0600-\u06FF]' })
        $untranslated | ForEach-Object { Write-Output "Untranslated: $($_.Name) = $($_.Value)" }
        $untranslated.Count | Should -Be 0
    }

    It "translates all Customize Preferences tweak labels and descriptions" {
        $ar = Get-Content (Join-Path $script:repoRoot "config\locales\ar.json") -Raw | ConvertFrom-Json
        $tweaks = Get-Content (Join-Path $script:repoRoot "config\tweaks.json") -Raw | ConvertFrom-Json
        $custom = @($tweaks.PSObject.Properties | Where-Object { $_.Value.category -eq 'Customize Preferences' })
        $custom.Count | Should -BeGreaterThan 0
        foreach ($p in $custom) {
            $short = $p.Name -replace '^WPFTweaks', ''
            $label = $ar.PSObject.Properties["s_tweak_$short"].Value
            $label | Should -Not -BeNullOrEmpty
            # Arabic text must contain at least one non-ASCII character.
            $label | Should -Match '[\u0600-\u06FF]'
            $desc = $ar.PSObject.Properties["s_desc_$short"].Value
            $desc | Should -Not -BeNullOrEmpty
            $desc | Should -Match '[\u0600-\u06FF]'
        }
    }

    It "keeps the top navigation bar left-to-right even in Arabic" {
        $xaml = Get-Content (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw
        $xaml | Should -Match 'Name="NavDockPanel"[^>]*FlowDirection="LeftToRight"'
        $xaml | Should -Match 'Name="GridBesideNavDockPanel"[^>]*FlowDirection="LeftToRight"'
    }

    It "reads language direction from config instead of hardcoding Arabic" {
        Get-WinUtilLanguageDirection -Language "ar" | Should -Be "RightToLeft"
        Get-WinUtilLanguageDirection -Language "en" | Should -Be "LeftToRight"
        Get-WinUtilLanguageDirection -Language "de" | Should -Be "LeftToRight"

        $languages = Get-Content (Join-Path $script:repoRoot "config\languages.json") -Raw | ConvertFrom-Json
        foreach ($code in @("en", "ar")) { $languages.PSObject.Properties[$code].Value.flowDirection | Should -BeIn @("LeftToRight", "RightToLeft") }
        @($languages.PSObject.Properties).Count | Should -BeGreaterOrEqual 32
        foreach ($p in $languages.PSObject.Properties) {
            $p.Value.flowDirection | Should -BeIn @("LeftToRight", "RightToLeft")
            Test-Path (Join-Path $script:repoRoot "config\locales\$($p.Name).json") | Should -BeTrue
        }
        $source = Get-Content (Join-Path $script:repoRoot "functions\private\Set-WinUtilLanguage.ps1") -Raw
        $source | Should -Not -Match 'Language -eq "ar"'
        $source | Should -Match 'Get-WinUtilLanguageDirection'
        $source | Should -Match 'appscategory\.Children\.Clear\(\)'
        $source | Should -Match 'Initialize-WPFUI -targetGridName .appscategory.'
        $source | Should -Match 'Initialize-WinUtilTabContent -TabName \$tab'
        $source | Should -Match 'SettingsDialog'
        $source | Should -Match 'Set-WinUtilDialogText'
    }

    It "builds the language menu dynamically from config" {
        $xaml = Get-Content (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw
        $xaml | Should -Match 'Name="LanguageMenuItems"'
        $xaml | Should -Not -Match 'EnglishLanguageMenuItem'
        $xaml | Should -Not -Match 'ArabicLanguageMenuItem'
        $ui = Get-Content (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw
        $ui | Should -Match 'Initialize-WinUtilLanguageMenu'
        $menu = Get-Content (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilLanguageMenu.ps1") -Raw
        $menu | Should -Match 'displayNameKey'
        $menu | Should -Match 'SetResourceReference'
        $menu | Should -Match '\$this\.Tag'
    }

    It "provides a unified settings page with all settings sections" {
        $xaml = Get-Content (Join-Path $script:repoRoot "xaml\settingsDialog.xaml") -Raw
        $xaml | Should -Match '^<Window'
        $xaml | Should -Match 'WindowStyle="None"'
        $xaml | Should -Match 'Name="SettingsHeader"'
        $xaml | Should -Match 'Name="SettingsHeaderClose"'
        # Many languages require a wrapping panel, not a single horizontal row.
        $xaml | Should -Match '<WrapPanel Name="SettingsLanguageItems"'
        $xaml | Should -Not -Match '<StackPanel Name="SettingsLanguageItems"'
        foreach ($name in @('SettingsThemeAuto','SettingsThemeDark','SettingsThemeLight',
                            'SettingsFontScalingSlider','SettingsLanguageItems','SettingsWingetRadio',
                            'SettingsChocoRadio','SettingsImportButton','SettingsExportButton',
                            'SettingsExportReportButton','SettingsAboutButton','SettingsCloseButton')) {
            $xaml | Should -Match "Name=.$name."
        }
        # Technical controls in the settings dialog must not flip in RTL.
        @([regex]::Matches($xaml, 'FlowDirection="LeftToRight"')).Count | Should -BeGreaterOrEqual 3
        # Locales must carry the new section labels.
        $en = Get-Content (Join-Path $script:repoRoot "config\locales\en.json") -Raw | ConvertFrom-Json
        $ar = Get-Content (Join-Path $script:repoRoot "config\locales\ar.json") -Raw | ConvertFrom-Json
        foreach ($k in @('s_settings_title','s_settings_appearance','s_settings_language','s_settings_packages','s_settings_data')) {
            $en.PSObject.Properties[$k].Value | Should -Not -BeNullOrEmpty
            $ar.PSObject.Properties[$k].Value | Should -Not -BeNullOrEmpty
        }
        $wiring = Get-Content (Join-Path $script:repoRoot "functions\private\Initialize-WinUtilSettingsPage.ps1") -Raw
        $wiring | Should -Match 'function Show-WinUtilSettingsDialog'
        $wiring | Should -Match 'settingsDialogXaml'
        $wiring | Should -Match 'ShowDialog\(\)'
        $wiring | Should -Match 'Invoke-WinutilThemeChange'
        $wiring | Should -Match 'MinWidth'
        $wiring | Should -Match 'Set-WinUtilDialogText'
        $ui = Get-Content (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw
        $ui | Should -Match 'Show-WinUtilSettingsDialog'
        $mainXaml = Get-Content (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw
        $mainXaml | Should -Not -Match 'WPFSettingsOverlay'
    }

    It "localizes Install panel descriptions through the passed description prefix" {
        $render = Get-Content (Join-Path $script:repoRoot "functions\public\Invoke-WPFUIElements.ps1") -Raw
        $render | Should -Match 'DescriptionPrefix'
        $render | Should -Not -Match 'Get-Localized -Key "s_desc_\$shortKey"'
        $ui = Get-Content (Join-Path $script:repoRoot "functions\public\Initialize-WPFUI.ps1") -Raw
        $ui | Should -Match "-DescriptionPrefix 's_appnav_desc_'"
        $ar = Get-Content (Join-Path $script:repoRoot "config\locales\ar.json") -Raw | ConvertFrom-Json
        $ar.PSObject.Properties['s_appnav_desc_WPFGetInstalled'].Value | Should -Be 'عرض التطبيقات المثبّتة'
    }

    It "localizes all wizard card step text" {
        $en = Get-Content (Join-Path $script:repoRoot "config\locales\en.json") -Raw | ConvertFrom-Json
        $ar = Get-Content (Join-Path $script:repoRoot "config\locales\ar.json") -Raw | ConvertFrom-Json
        foreach ($step in @('restorepoint','install','tweaks','config','updates','appx','review')) {
            foreach ($suffix in @('title','desc','changes','benefits','info')) {
                $key = "s_guide_${step}_${suffix}"
                $en.PSObject.Properties[$key] | Should -Not -BeNull
                $ar.PSObject.Properties[$key] | Should -Not -BeNull
            }
        }
    }

    It "uses DynamicResource keys for all localized XAML attributes" {
        $xaml = Get-Content (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw
        $xaml | Should -Match 'Header="\{DynamicResource s_install\}"'
        $xaml | Should -Match 'AutomationProperties\.Name="\{DynamicResource s_iso_file\}"'
        $xaml | Should -Match 'Header="\{DynamicResource s_about\}"'
        # No English literals left as attribute values
        $xaml | Should -Not -Match 'Content="Apply Recommended"'
        $xaml | Should -Not -Match 'Text="Choose applications"'
    }
}
