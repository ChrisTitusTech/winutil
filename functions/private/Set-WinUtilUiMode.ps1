function Get-WinUtilGuideBrush {
    <#
    .SYNOPSIS
        Resolves a theme brush for guide visuals, with a safe fallback for headless tests.
    #>
    param([Parameter(Mandatory)][string]$Name)

    try {
        $resource = $sync.Form.TryFindResource($Name)
        if ($resource -is [System.Windows.Media.Brush]) { return $resource }
    } catch { }
    return [System.Windows.Media.Brushes]::DimGray
}

function Get-WinUtilGuideText {
    <#
    .SYNOPSIS
        Returns a localized guide string for the current language.
    #>
    param([Parameter(Mandatory)][string]$Key)

    $language = Get-WinUtilLanguage
    $locales = $sync.configs.locales
    $locale = if ($locales -is [System.Collections.IDictionary]) { $locales[$language] } else { $locales.$language }
    if ($null -ne $locale) {
        $property = $locale.PSObject.Properties[$Key]
        if ($null -ne $property) { return [string]$property.Value }
    }
    return $Key
}

function Get-WinUtilGuideDotBrush {
    <#
    .SYNOPSIS
        Returns the fixed, full-opacity brush for a guide step state.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Active", "Completed", "Skipped", "Upcoming")]
        [string]$State
    )

    $resourceName = "GuideDot${State}Brush"
    try {
        $resource = $sync.Form.TryFindResource($resourceName)
        if ($resource -is [System.Windows.Media.Brush]) { return $resource }
    } catch { }

    # Fallback for headless runs: same fixed colours as the XAML resources
    $colour = switch ($State) {
        "Active" { [System.Windows.Media.Color]::FromRgb(0x2E, 0x9B, 0x57) }
        "Completed" { [System.Windows.Media.Color]::FromRgb(0x2F, 0x7F, 0xD1) }
        "Skipped" { [System.Windows.Media.Color]::FromRgb(0xE3, 0x9B, 0x2B) }
        default { [System.Windows.Media.Color]::FromRgb(0xB9, 0xB9, 0xB9) }
    }
    return [System.Windows.Media.SolidColorBrush]::new($colour)
}

function Set-WinUtilGuidePowerPlan {
    <#
    .SYNOPSIS
        Queues the built-in High Performance power plan activation.
    #>
    Start-WinUtilJob -Name "High Performance" -Description "Activating the High Performance power plan" -QueueIfBusy -ScriptBlock {
        $scheme = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
        powercfg /setactive $scheme
        if ($LASTEXITCODE -ne 0) {
            throw "powercfg could not activate the High Performance plan (exit code $LASTEXITCODE)."
        }
        Write-Host "High Performance power plan enabled."
    }
}

function Set-WinUtilUiMode {
    <#
    .SYNOPSIS
        Applies the mode chosen on the startup chooser.

    .DESCRIPTION
        Advanced keeps the original tab interface. Setup replaces it with a seven-step decision
        wizard whose content comes from config/guide.json. The choice is per session.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Setup", "Advanced")]
        [string]$Mode
    )

    $sync.UiMode = $Mode
    $sync.WPFModeSelectionOverlay.Visibility = "Collapsed"

    if ($Mode -eq "Advanced") {
        $sync.NavDockPanel.Visibility = "Visible"
        $sync.WPFTabNav.Visibility = "Visible"
        $sync.WPFGuidePanel.Visibility = "Collapsed"
        $sync.WPFGuideFooter.Visibility = "Collapsed"
        $sync.WPFGuidePowerPanel.Visibility = "Collapsed"
        if ($null -ne $sync.WPFTweaksbutton) { $sync.WPFTweaksbutton.Visibility = "Visible" }

        # Offline starts on Tweaks because the Install tab is disabled there.
        $installEnabled = $null -eq $sync.WPFTab1BT -or $sync.WPFTab1BT.IsEnabled
        Invoke-WPFTab $(if ($installEnabled) { "WPFTab1BT" } else { "WPFTab2BT" }) -Yield
    } else {
        $sync.NavDockPanel.Visibility = "Collapsed"
        $sync.WPFTabNav.Visibility = "Collapsed"
        $sync.WPFGuidePanel.Visibility = "Visible"
        $sync.WPFGuideFooter.Visibility = "Visible"
        $sync.SearchBar.Visibility = "Collapsed"
        if ($null -ne $sync.SearchBarClearButton) { $sync.SearchBarClearButton.Visibility = "Collapsed" }

        $steps = @("RestorePoint", "Install", "Tweaks", "Config", "Updates", "AppX", "Review")
        $sync.GuideChoices = @{}
        foreach ($name in $steps) {
            $entry = $sync.configs.guide.$name
            if ($null -eq $entry) { continue }
            if ($null -ne $entry.Default) { $sync.GuideChoices[$name] = $entry.Default }
            elseif ($entry.Kind -eq "Options" -and @($entry.Options).Count -gt 0) { $sync.GuideChoices[$name] = [string]$entry.Options[0].Value }
            else { $sync.GuideChoices[$name] = $false }
        }

        $sync.GuideSkipped = [System.Collections.Generic.HashSet[string]]::new()
        $sync.GuideDynamicPackages = [System.Collections.Generic.List[object]]::new()
        $sync.GuideConfigInitialized = $false
        $sync.GuideIsLaptop = $false
        try {
            $batteries = @(Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue)
            $sync.GuideIsLaptop = ($batteries.Count -gt 0)
        } catch { }

        $selectedApps = [System.Collections.Generic.List[string]]::new()
        foreach ($app in @($sync.selectedApps | Where-Object { $_ })) { $selectedApps.Add([string]$app) }
        $sync.selectedApps = $selectedApps

        Initialize-WinUtilGuideApps
        if ($null -ne $sync.WPFGuideAppSearch) {
            $sync.WPFGuideAppSearch.Add_TextChanged({ Set-WinUtilGuideAppFilter -Text $this.Text })
        }
        Set-WinUtilGuideStep -Step 1
    }

    Write-WinUtilLog -Component "UI" -Message "Interface mode: $Mode."
}

function Initialize-WinUtilGuideApps {
    <#
    .SYNOPSIS
        Builds the categorized application picker with bundled icons and a tick checkbox.

    .DESCRIPTION
        Cards are generated as one XAML document per category, the same way the Advanced Install
        tab builds its entries, so several hundred apps do not cost one PowerShell call per element.
    #>
    $panel = $sync.WPFGuideAppList
    if ($null -eq $panel) { return }
    $panel.Children.Clear()

    $sync.GuideAppCards = [System.Collections.Generic.List[object]]::new()
    $sync.GuideAppCategories = [System.Collections.Generic.List[object]]::new()

    $appsByCategory = @{}
    foreach ($key in @($sync.configs.applicationsHashtable.Keys | Sort-Object)) {
        $app = $sync.configs.applicationsHashtable[$key]
        if ($null -eq $app) { continue }
        $category = if ($app.category) { [string]$app.category } else { "Other" }
        if (-not $appsByCategory.ContainsKey($category)) { $appsByCategory[$category] = [System.Collections.Generic.List[string]]::new() }
        $appsByCategory[$category].Add([string]$key)
    }

    foreach ($category in @($appsByCategory.Keys | Sort-Object)) {
        $header = New-Object System.Windows.Controls.Label
        $catKey = 's_appcat_' + (($category -replace '[^A-Za-z0-9]+', '_').ToLowerInvariant())
        $header.Content = Get-WinUtilGuideText -Key $catKey
        $header.FlowDirection = "LeftToRight"
        $header.FontWeight = "Bold"
        $header.FontSize = 14
        $foreground = Get-WinUtilGuideBrush -Name "LabelboxForegroundColor"
        if ($foreground) { $header.Foreground = $foreground }
        $header.Margin = [System.Windows.Thickness]::new(0, 10, 0, 4)
        $panel.Children.Add($header) | Out-Null

        $wrap = New-Object System.Windows.Controls.WrapPanel
        $wrap.Orientation = "Horizontal"
        $wrap.FlowDirection = "LeftToRight"
        $panel.Children.Add($wrap) | Out-Null
        $sync.GuideAppCategories.Add([pscustomobject]@{ Category = $category; Header = $header; Panel = $wrap })

        $document = [System.Text.StringBuilder]::new()
        [void]$document.Append('<WrapPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">')
        $icons = @{}
        $cardKeys = [System.Collections.Generic.List[string]]::new()

        foreach ($appKey in @($appsByCategory[$category] | Sort-Object)) {
            $app = $sync.configs.applicationsHashtable[$appKey]
            $icon = Get-WinUtilAppIcon -Key ($appKey -replace '^WPFInstall', '')
            $icons[$appKey] = $icon
            $cardKeys.Add($appKey)

            $name = [Security.SecurityElement]::Escape([string]$app.content)
            $description = [Security.SecurityElement]::Escape([string]$app.description)
            $keyText = [Security.SecurityElement]::Escape($appKey)
            $id = 'GuideApp_' + ($appKey -replace '[^A-Za-z0-9_]', '_')
            $letter = [Security.SecurityElement]::Escape(([string]$app.content).TrimStart('.').Substring(0, 1).ToUpper())
            $letterVisibility = if ($icon) { ' Visibility="Collapsed"' } else { '' }

            [void]$document.Append(@"
<Border Style="{DynamicResource AppEntryBorderStyle}" Width="Auto" MinWidth="260" Tag="$keyText" ToolTip="$description" AutomationProperties.Name="$name"><Grid><CheckBox x:Name="$id" Tag="$keyText" Style="{DynamicResource GuideCircularCheckBox}" AutomationProperties.Name="$name"><StackPanel Orientation="Horizontal" VerticalAlignment="Center"><Border Style="{DynamicResource AppEntryIconPlateStyle}"><Grid><TextBlock Style="{DynamicResource AppEntryIconLetterStyle}" Text="$letter"$letterVisibility/><Image x:Name="Icon_$id" Style="{DynamicResource AppEntryIconStyle}"/></Grid></Border><TextBlock Style="{DynamicResource AppEntryNameStyle}" Text="$name"/></StackPanel></CheckBox></Grid></Border>
"@)
        }
        [void]$document.Append('</WrapPanel>')

        $parsed = [Windows.Markup.XamlReader]::Parse($document.ToString())
        $checkBoxes = [System.Collections.Generic.List[object]]::new()

        foreach ($appKey in $cardKeys) {
            $app = $sync.configs.applicationsHashtable[$appKey]
            $id = 'GuideApp_' + ($appKey -replace '[^A-Za-z0-9_]', '_')
            $check = $parsed.FindName($id)
            if ($null -eq $check) { continue }
            $border = $check.Parent.Parent
            $border.FlowDirection = "LeftToRight"

            $icon = $icons[$appKey]
            if ($icon) { $parsed.FindName("Icon_$id").Source = $icon }

            $check.Add_Checked({
                $selectedKey = [string]$this.Tag
                if (-not $sync.selectedApps.Contains($selectedKey)) { $sync.selectedApps.Add($selectedKey) }
            })
            $check.Add_Unchecked({
                $selectedKey = [string]$this.Tag
                $null = $sync.selectedApps.Remove($selectedKey)
            })

            $sync.GuideAppCards.Add([pscustomobject]@{
                Category = $category
                Key = $appKey
                Name = [string]$app.content
                Description = [string]$app.description
                Border = $border
            })
            $checkBoxes.Add($check)
        }

        $entries = @($parsed.Children)
        $parsed.Children.Clear()
        foreach ($entry in $entries) { $wrap.Children.Add($entry) | Out-Null }

        # Attach last so an app chosen earlier is reflected in its card
        foreach ($check in $checkBoxes) {
            if ($sync.selectedApps -contains $check.Tag) { $check.IsChecked = $true }
        }
    }
}

function Set-WinUtilGuideAppFilter {
    <#
    .SYNOPSIS
        Filters the simple-mode app cards by name, description or key.
    #>
    param([string]$Text)

    $needle = if ($Text) { $Text.Trim() } else { "" }
    foreach ($card in @($sync.GuideAppCards)) {
        $visible = [string]::IsNullOrEmpty($needle)
        if (-not $visible) {
            $visible = $card.Name.IndexOf($needle, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
                       ([string]$card.Description).IndexOf($needle, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
                       $card.Key.IndexOf($needle, [StringComparison]::OrdinalIgnoreCase) -ge 0
        }
        $card.Border.Visibility = $(if ($visible) { "Visible" } else { "Collapsed" })
    }

    foreach ($category in @($sync.GuideAppCategories)) {
        $any = $false
        foreach ($card in @($sync.GuideAppCards)) {
            if ($card.Category -eq $category.Category -and $card.Border.Visibility -ne "Collapsed") {
                $any = $true
                break
            }
        }
        $category.Header.Visibility = $(if ($any) { "Visible" } else { "Collapsed" })
        $category.Panel.Visibility = $(if ($any) { "Visible" } else { "Collapsed" })
    }
}

function Set-WinUtilGuideStep {
    <#
    .SYNOPSIS
        Renders one of the seven simple-mode steps.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, 7)]
        [int]$Step
    )

    $steps = @("RestorePoint", "Install", "Tweaks", "Config", "Updates", "AppX", "Review")
    $name = $steps[$Step - 1]
    $sync.GuideStep = $Step
    $sync.GuideStepName = $name

    $sync.WPFGuideCurrentLabel.Text = "Step $Step"
    $sync.WPFGuideBackButton.IsEnabled = ($Step -gt 1)
    $sync.WPFGuideNextButton.IsEnabled = ($Step -lt 7)
    $sync.WPFGuideSkipButton.Visibility = $(if ($Step -lt 7) { "Visible" } else { "Collapsed" })
    if ($null -ne $sync.WPFGuideTotalLabel) { $sync.WPFGuideTotalLabel.Text = "7 steps" }

    for ($index = 1; $index -le 7; $index++) {
        $dot = $sync["WPFGuideDot$index"]
        if ($null -eq $dot) { continue }
        $state = if ($steps[$index - 1] -in $sync.GuideSkipped) {
            "Skipped"
        } elseif ($index -eq $Step) {
            "Active"
        } elseif ($index -lt $Step) {
            "Completed"
        } else {
            "Upcoming"
        }
        $dot.Fill = Get-WinUtilGuideDotBrush -State $state
    }

    # Tweaks and Config keep their full Advanced UI, including every tweak detail and feature
    # checkbox. The wizard footer stays below the tab control so navigation is still available.
    if ($name -in @("Tweaks", "Config")) {
        $sync.WPFGuidePanel.Visibility = "Collapsed"
        $sync.WPFTabNav.Visibility = "Visible"
        $sync.WPFGuidePowerPanel.Visibility = $(if ($name -eq "Config") { "Visible" } else { "Collapsed" })
        if ($null -ne $sync.WPFTweaksbutton) { $sync.WPFTweaksbutton.Visibility = "Collapsed" }
        if ($name -eq "Config") {
            if (-not $sync.GuideConfigInitialized) {
                $sync.GuideConfigInitialized = $true
                $sync.selectedFeatures = @($sync.configs.guide.Config.DefaultFeatures)
                Reset-WPFCheckBoxes -doToggles $false -checkboxfilterpattern "WPFFeature*"
            }
            # Warmup may have built Config before a mode was chosen, when the filter was inactive.
            # Rebuild it now so Legacy Windows Panels is removed in Simple mode.
            $sync.InitializedTabs["Config"] = $false
        }
        Invoke-WPFTab $(if ($name -eq "Tweaks") { "WPFTab2BT" } else { "WPFTab3BT" }) -Yield
        return
    }

    $sync.WPFTabNav.Visibility = "Collapsed"
    $sync.WPFGuidePanel.Visibility = "Visible"
    $sync.WPFGuidePowerPanel.Visibility = "Collapsed"
    if ($null -ne $sync.SearchBar) { $sync.SearchBar.Visibility = "Collapsed" }

    $isInstall = $name -eq "Install"
    $isReview = $name -eq "Review"
    $sync.WPFGuideCard.Visibility = $(if (-not $isInstall -and -not $isReview) { "Visible" } else { "Collapsed" })
    $sync.WPFGuideAppPanel.Visibility = $(if ($isInstall) { "Visible" } else { "Collapsed" })
    $sync.WPFGuideReviewPanel.Visibility = $(if ($isReview) { "Visible" } else { "Collapsed" })

    if ($isReview) {
        $sync.WPFGuideSummary.Text = Get-WinUtilGuideSummary
        return
    }
    if ($isInstall) { return }

    $entry = $sync.configs.guide.$name
    if ($null -eq $entry) { return }

    $lower = $name.ToLowerInvariant()
    $sync.WPFGuideTitle.Text = Get-WinUtilGuideText -Key "s_guide_${lower}_title"
    $sync.WPFGuideDescription.Text = Get-WinUtilGuideText -Key "s_guide_${lower}_desc"
    $sync.WPFGuideChanges.Text = (Get-WinUtilGuideText -Key "s_guide_${lower}_changes") -replace "`n", "`n• "
    $sync.WPFGuideBenefits.Text = (Get-WinUtilGuideText -Key "s_guide_${lower}_benefits") -replace "`n", "`n• "
    $sync.WPFGuideChanges.Text = "• " + $sync.WPFGuideChanges.Text
    $sync.WPFGuideBenefits.Text = "• " + $sync.WPFGuideBenefits.Text
    $sync.WPFGuideInfo.Text = Get-WinUtilGuideText -Key "s_guide_${lower}_info"
    $sync.WPFGuideUndoBadge.Visibility = $(if ($entry.Undoable) { "Visible" } else { "Collapsed" })

    $warningText = Get-WinUtilGuideText -Key "s_guide_${lower}_warning"
    $warningVisible = $warningText -ne "s_guide_${lower}_warning" -and (-not $entry.WarningIfBattery -or $sync.GuideIsLaptop)
    $sync.WPFGuideWarning.Visibility = $(if ($warningVisible) { "Visible" } else { "Collapsed" })
    $sync.WPFGuideWarningText.Text = $warningText

    $isBoolean = $entry.Kind -eq "Boolean"
    $sync.WPFGuideBooleanActions.Visibility = $(if ($isBoolean) { "Visible" } else { "Collapsed" })
    $sync.WPFGuideOptions.Visibility = $(if ($entry.Kind -eq "Options") { "Visible" } else { "Collapsed" })

    if ($isBoolean) {
        $chosen = [bool]$sync.GuideChoices[$name]
        $sync.WPFGuideYesButton.Background = Get-WinUtilGuideBrush -Name $(if ($chosen) { "ButtonBackgroundSelectedColor" } else { "ButtonBackgroundColor" })
        $sync.WPFGuideNoButton.Background = Get-WinUtilGuideBrush -Name $(if (-not $chosen) { "ButtonBackgroundSelectedColor" } else { "ButtonBackgroundColor" })
        return
    }

    if ($entry.Kind -eq "Options") {
        for ($index = 1; $index -le 4; $index++) {
            $button = $sync["WPFGuideOption$index"]
            if ($null -eq $button) { continue }
            $option = $entry.Options[$index - 1]
            if ($null -eq $option) {
                $button.Visibility = "Collapsed"
                continue
            }
            $button.Visibility = "Visible"
            $value = [string]$option.Value
            $optionKey = switch ($value) {
                "None" { "s_option_none" }
                "Standard" { "s_option_standard" }
                "Minimal" { "s_option_minimal" }
                "Advanced" { "s_option_advanced" }
                "Keep" { "s_option_keep" }
                "Recommended" { "s_option_recommended" }
                "Defaults" { "s_option_defaults" }
                "Disable" { "s_option_disable" }
                default { $null }
            }
            $button.Content = if ($optionKey) { Get-WinUtilGuideText -Key $optionKey } else { [string]$option.Label }
            $button.Tag = $value
            $button.Background = Get-WinUtilGuideBrush -Name $(if ([string]$sync.GuideChoices[$name] -eq [string]$option.Value) { "ButtonBackgroundSelectedColor" } else { "ButtonBackgroundColor" })
        }
    }
}

function Move-WinUtilGuideStep {
    <#
    .SYNOPSIS
        Moves to the previous or next simple-mode step.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Previous", "Next")]
        [string]$Direction
    )

    $target = [int]$sync.GuideStep + $(if ($Direction -eq "Next") { 1 } else { -1 })
    if ($target -ge 1 -and $target -le 7) {
        Set-WinUtilGuideStep -Step $target
    }
}

function Set-WinUtilGuideChoice {
    <#
    .SYNOPSIS
        Records a Yes/No decision and advances to the next step.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Yes", "No")]
        [string]$Choice
    )

    $name = [string]$sync.GuideStepName
    if ([string]::IsNullOrWhiteSpace($name)) { return }
    $sync.GuideChoices[$name] = ($Choice -eq "Yes")
    [void]$sync.GuideSkipped.Remove($name)
    if ([int]$sync.GuideStep -lt 7) { Set-WinUtilGuideStep -Step ([int]$sync.GuideStep + 1) }
}

function Set-WinUtilGuideOption {
    <#
    .SYNOPSIS
        Records the option chosen on a preset/profile card.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, 4)]
        [int]$Index
    )

    $button = $sync["WPFGuideOption$Index"]
    if ($null -eq $button -or $null -eq $button.Tag) { return }
    $name = [string]$sync.GuideStepName
    if ([string]::IsNullOrWhiteSpace($name)) { return }

    $sync.GuideChoices[$name] = [string]$button.Tag
    [void]$sync.GuideSkipped.Remove($name)
    Set-WinUtilGuideStep -Step ([int]$sync.GuideStep)
}

function Set-WinUtilGuideStepSkipped {
    <#
    .SYNOPSIS
        Marks the current step skipped and advances.
    #>
    $name = [string]$sync.GuideStepName
    if (-not [string]::IsNullOrWhiteSpace($name)) { [void]$sync.GuideSkipped.Add($name) }
    if ([int]$sync.GuideStep -lt 7) { Set-WinUtilGuideStep -Step ([int]$sync.GuideStep + 1) }
}

function Get-WinUtilGuideSummary {
    <#
    .SYNOPSIS
        Builds the read-only summary shown on the review step.
    #>
    $lines = [System.Collections.Generic.List[string]]::new()
    $t = { param([string]$k) Get-WinUtilGuideText -Key $k }

    foreach ($name in @("RestorePoint", "Install", "Tweaks", "Config", "Updates", "AppX")) {
        if ($name -in $sync.GuideSkipped) {
            $lines.Add("$($name) : $(& $t 's_summary_skipped')")
            continue
        }

        $choice = $sync.GuideChoices[$name]
        switch ($name) {
            "RestorePoint" {
                $lines.Add("$( & $t 's_summary_restore_point') : $(if ($choice) { & $t 's_summary_yes' } else { & $t 's_summary_no' })")
            }
            "Install" {
                $apps = @($sync.selectedApps | Where-Object { $_ })
                $labels = @($apps | ForEach-Object {
                    $entry = $sync.configs.applicationsHashtable.$_
                    if ($entry -and $entry.content) { [string]$entry.content } else { [string]$_ }
                })
                $none = & $t 's_summary_none'
                $lines.Add("$(& $t 's_summary_applications') ($($apps.Count)) : $(if ($labels.Count) { $labels -join ', ' } else { $none })")
                $dynamic = @($sync.GuideDynamicPackages)
                if ($dynamic.Count -gt 0) {
                    $names = @($dynamic | ForEach-Object { "$($_.Name) [$($_.Source)]" })
                    $lines.Add("$(& $t 's_summary_searched') ($($dynamic.Count)) : $($names -join ', ')")
                }
            }
            "Tweaks" {
                $manual = @($sync.selectedTweaks | Where-Object { $_ })
                if ($choice -in @("Standard", "Minimal", "Advanced")) {
                    $presetName = [string]$choice
                    $keys = @($sync.configs.preset.$presetName)
                    $label = & $t "s_option_$($presetName.ToLowerInvariant())"
                    $lines.Add("$(& $t 's_summary_tweaks') : $label ($($keys.Count))")
                } elseif ($manual.Count -gt 0) {
                    $lines.Add("$(& $t 's_summary_tweaks') : $(& $t 's_option_advanced') ($($manual.Count))")
                } else {
                    $lines.Add("$(& $t 's_summary_tweaks') : $(& $t 's_summary_none')")
                }
            }
            "Config" {
                $features = @($sync.selectedFeatures | Where-Object { $_ })
                if ($features.Count -gt 0) {
                    $lines.Add("$(& $t 's_summary_features') ($($features.Count)) : $($features -join ', ')")
                } else {
                    $lines.Add("$(& $t 's_summary_features') : $(& $t 's_summary_none')")
                }
                if ($sync.WPFGuideHighPerformance.IsChecked) {
                    $lines.Add("$(& $t 's_summary_power') : $(& $t 's_summary_high_performance')")
                }
            }
            "Updates" {
                $label = switch ([string]$choice) {
                    "Keep" { & $t 's_option_keep' }
                    "Recommended" { & $t 's_option_recommended' }
                    "Defaults" { & $t 's_option_defaults' }
                    "Disable" { & $t 's_option_disable' }
                    default { [string]$choice }
                }
                $lines.Add("$(& $t 's_windows_update_profiles') : $label")
            }
            "AppX" {
                if ($choice) {
                    $keys = @($sync.configs.preset.AppxDefault)
                    $lines.Add("$(& $t 's_summary_appx') : $(& $t 's_summary_yes') ($($keys.Count))")
                } else {
                    $lines.Add("$(& $t 's_summary_appx') : $(& $t 's_summary_no')")
                }
            }
        }
    }

    return ($lines -join [Environment]::NewLine)
}

function Invoke-WinUtilGuideApplyAll {
    <#
    .SYNOPSIS
        Queues every accepted decision in the safest order.
    #>
    $performed = [System.Collections.Generic.List[string]]::new()

    # Restore point is handled inside the tweaks job, which runs it before anything else changes.
    $tweaks = [System.Collections.Generic.List[string]]::new()
    $tweakChoice = [string]$sync.GuideChoices["Tweaks"]
    if ("Tweaks" -notin $sync.GuideSkipped) {
        if ($tweakChoice -in @("Standard", "Minimal", "Advanced")) {
            foreach ($key in @($sync.configs.preset.$tweakChoice)) { $tweaks.Add([string]$key) }
        } else {
            # Custom (or no preset clicked): use the tweaks picked in the full Advanced list
            foreach ($key in @($sync.selectedTweaks | Where-Object { $_ })) { $tweaks.Add([string]$key) }
        }
    }
    if ("RestorePoint" -notin $sync.GuideSkipped -and [bool]$sync.GuideChoices["RestorePoint"]) {
        if (-not $tweaks.Contains("WPFTweaksRestorePoint")) { $tweaks.Insert(0, "WPFTweaksRestorePoint") }
    } else {
        $null = $tweaks.Remove("WPFTweaksRestorePoint")
    }
    if ($tweaks.Count -gt 0) {
        $sync.selectedTweaks = @($tweaks)
        Invoke-WPFtweaksbutton
        $performed.Add("Tweaks ($($tweaks.Count) tweaks)")
    }

    $apps = @($sync.selectedApps | Where-Object { $_ })
    if ("Install" -notin $sync.GuideSkipped -and $apps.Count -gt 0) {
        Invoke-WPFInstall
        $performed.Add("Install ($($apps.Count) apps)")
    }

    $dynamic = @($sync.GuideDynamicPackages)
    if ("Install" -notin $sync.GuideSkipped -and $dynamic.Count -gt 0) {
        Invoke-WinUtilGuideDynamicInstall -Packages $dynamic
        $performed.Add("Searched packages ($($dynamic.Count))")
    }

    if ("Config" -notin $sync.GuideSkipped) {
        $features = @($sync.selectedFeatures | Where-Object { $_ })
        if ($features.Count -gt 0) {
            Invoke-WPFFeatureInstall
            $performed.Add("Features ($($features.Count) features)")
        }
        if ($sync.WPFGuideHighPerformance.IsChecked) {
            Set-WinUtilGuidePowerPlan
            $performed.Add("High Performance power plan")
        }
    }

    if ("AppX" -notin $sync.GuideSkipped -and [bool]$sync.GuideChoices["AppX"]) {
        $packages = @($sync.configs.preset.AppxDefault)
        $sync.selectedAppx = $packages
        Invoke-WPFAppxRemoval
        $performed.Add("AppX ($($packages.Count) packages)")
    }

    if ("Updates" -notin $sync.GuideSkipped) {
        $profile = [string]$sync.GuideChoices["Updates"]
        $button = switch ($profile) {
            "Recommended" { "WPFUpdatessecurity" }
            "Defaults" { "WPFUpdatesdefault" }
            "Disable" { "WPFUpdatesdisable" }
            default { $null }
        }
        if ($button) {
            Invoke-WPFButton -Button $button
            $performed.Add("Updates ($profile)")
        }
    }

    if ($performed.Count -eq 0) {
        Show-WinUtilMessage -Message "Nothing to apply. Go back and choose at least one action, or press Skip on a step you do not want."
        return
    }

    foreach ($action in $performed) {
        Write-WinUtilLog -Component "Guide" -Message "Queued: $action"
    }
    Write-WinUtilLog -Component "Guide" -Message "Apply all in order requested ($($performed.Count) action group(s))."
}
