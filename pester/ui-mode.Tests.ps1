#===========================================================================
# Tests - Startup mode chooser and the seven-step Setup mode wizard
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:xamlPath = Join-Path $script:repoRoot "xaml\inputXML.xaml"
    $script:guidePath = Join-Path $script:repoRoot "config\guide.json"
    $script:localeScript = Join-Path $script:repoRoot "functions\private\Set-WinUtilLanguage.ps1"
    $script:uiModeScript = Join-Path $script:repoRoot "functions\private\Set-WinUtilUiMode.ps1"
    $script:buttonScript = Join-Path $script:repoRoot "functions\public\Invoke-WPFButton.ps1"
    $script:packageSearchScript = Join-Path $script:repoRoot "functions\private\Invoke-WinUtilPackageSearch.ps1"

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    [xml]$script:xaml = Get-Content -Path $script:xamlPath -Raw
    $script:guide = Get-Content -Path $script:guidePath -Raw | ConvertFrom-Json
    . $script:localeScript
    . $script:uiModeScript
    . $script:packageSearchScript

    function Invoke-WPFTab { param([string]$ClickedTab, [switch]$Yield) }
    function Write-WinUtilLog { param($Component, $Message, $Level) }
    function Get-WinUtilAppIcon { param([Parameter(Mandatory)][string]$Key) return $null }
    function Reset-WPFCheckBoxes { param([bool]$doToggles = $false, [string]$checkboxfilterpattern = "**") }
    function Start-WinUtilJob { param([string]$Name, [scriptblock]$ScriptBlock, [hashtable]$Parameters, [string]$Description, [switch]$QueueIfBusy) }
    function winget { }
    function choco { }
    function Invoke-WPFtweaksbutton { }
    function Invoke-WPFInstall { }
    function Invoke-WPFFeatureInstall { }
    function Invoke-WPFAppxRemoval { }
    function Invoke-WPFButton { param([string]$Button) }
    function Show-WinUtilMessage { param($Message, $Title, $Button, $Icon) }
}

Describe "Startup mode UI" {
    BeforeEach {
        $form = New-Object PSObject
        $form | Add-Member -MemberType ScriptMethod -Name TryFindResource -Value { param($Name) return $null }

        $appList = New-Object PSObject
        $appList | Add-Member -MemberType NoteProperty -Name Children -Value ([System.Collections.ArrayList]::new())

        $appSearch = New-Object PSObject
        $appSearch | Add-Member -MemberType NoteProperty -Name Text -Value ""
        $appSearch | Add-Member -MemberType ScriptMethod -Name Add_TextChanged -Value { param($Handler) }

        $packageList = New-Object PSObject
        $packageList | Add-Member -MemberType NoteProperty -Name Children -Value ([System.Collections.ArrayList]::new())

        $script:sync = [Hashtable]::Synchronized(@{
            UiMode = $null
            GuideStep = 0
            GuideStepName = ""
            GuideChoices = @{}
            GuideSkipped = [System.Collections.Generic.HashSet[string]]::new()
            GuideIsLaptop = $false
            GuideConfigInitialized = $false
            GuideDynamicPackages = [System.Collections.Generic.List[object]]::new()
            InitializedTabs = @{}
            Form = $form
            WPFModeSelectionOverlay = [pscustomobject]@{ Visibility = "Visible" }
            NavDockPanel = [pscustomobject]@{ Visibility = "Visible" }
            WPFTabNav = [pscustomobject]@{ Visibility = "Visible" }
            WPFGuidePanel = [pscustomobject]@{ Visibility = "Collapsed" }
            WPFGuideFooter = [pscustomobject]@{ Visibility = "Collapsed" }
            WPFGuidePowerPanel = [pscustomobject]@{ Visibility = "Collapsed" }
            WPFGuideHighPerformance = [pscustomobject]@{ IsChecked = $false }
            WPFTweaksbutton = [pscustomobject]@{ Visibility = "Visible" }
            SearchBar = [pscustomobject]@{ Visibility = "Visible" }
            SearchBarClearButton = [pscustomobject]@{ Visibility = "Collapsed" }
            WPFTab1BT = [pscustomobject]@{ IsEnabled = $true }
            WPFGuideAppList = $appList
            WPFGuideAppSearch = $appSearch
            WPFGuideSearchPackagesButton = [pscustomobject]@{ Visibility = "Visible" }
            WPFGuideSearchStatus = [pscustomobject]@{ Text = "" }
            WPFGuidePackageResults = [pscustomobject]@{ Visibility = "Collapsed" }
            WPFGuidePackageList = $packageList
            WPFGuideCurrentLabel = [pscustomobject]@{ Text = "" }
            WPFGuideTotalLabel = [pscustomobject]@{ Text = "" }
            WPFGuideBackButton = [pscustomobject]@{ IsEnabled = $false }
            WPFGuideNextButton = [pscustomobject]@{ IsEnabled = $true }
            WPFGuideSkipButton = [pscustomobject]@{ Visibility = "Visible" }
            WPFGuideCard = [pscustomobject]@{ Visibility = "Collapsed" }
            WPFGuideAppPanel = [pscustomobject]@{ Visibility = "Collapsed" }
            WPFGuideReviewPanel = [pscustomobject]@{ Visibility = "Collapsed" }
            WPFGuideTitle = [pscustomobject]@{ Text = "" }
            WPFGuideDescription = [pscustomobject]@{ Text = "" }
            WPFGuideChanges = [pscustomobject]@{ Text = "" }
            WPFGuideBenefits = [pscustomobject]@{ Text = "" }
            WPFGuideInfo = [pscustomobject]@{ Text = "" }
            WPFGuideWarningText = [pscustomobject]@{ Text = "" }
            WPFGuideSummary = [pscustomobject]@{ Text = "" }
            WPFGuideUndoBadge = [pscustomobject]@{ Visibility = "Collapsed" }
            WPFGuideWarning = [pscustomobject]@{ Visibility = "Collapsed" }
            WPFGuideBooleanActions = [pscustomobject]@{ Visibility = "Collapsed" }
            WPFGuideOptions = [pscustomobject]@{ Visibility = "Collapsed" }
            WPFGuideYesButton = [pscustomobject]@{ Background = $null }
            WPFGuideNoButton = [pscustomobject]@{ Background = $null }
            WPFGuideApplyAllButton = [pscustomobject]@{ Visibility = "Visible" }
            selectedApps = @()
            selectedTweaks = @()
            selectedFeatures = @()
            selectedAppx = @()
            preferences = @{ language = "en" }
            configs = @{
                guide = $script:guide
                locales = @{
                    en = Get-Content (Join-Path $script:repoRoot "config\locales\en.json") -Raw | ConvertFrom-Json
                    ar = Get-Content (Join-Path $script:repoRoot "config\locales\ar.json") -Raw | ConvertFrom-Json
                }
                preset = @{
                    Standard = @("WPFTweaksActivity")
                    Minimal = @("WPFTweaksWPBT")
                    Advanced = @("WPFTweaksRestorePoint")
                    AppxDefault = @("WPFAppxFoo")
                }
                applicationsHashtable = @{
                    "WPFInstall7zip" = [pscustomobject]@{ content = "7-Zip" }
                    "WPFInstallcurl" = [pscustomobject]@{ content = "curl" }
                }
            }
        })

        foreach ($index in 1..7) {
            $script:sync["WPFGuideDot$index"] = [pscustomobject]@{ Fill = $null }
            $script:sync["WPFGuideOption$index"] = [pscustomobject]@{ Visibility = "Collapsed"; Content = ""; Tag = $null; Background = $null }
        }

        $script:calls = [System.Collections.ArrayList]::new()
        Mock Invoke-WPFTab { }
        Mock Write-WinUtilLog { }
        Mock Get-WinUtilGuideBrush { return $null }
        Mock Get-WinUtilAppIcon { return $null }
        Mock Reset-WPFCheckBoxes { }
        Mock Start-WinUtilJob { $null = $script:calls.Add("HighPerformance") }
        Mock Invoke-WinUtilGuideDynamicInstall { $null = $script:calls.Add("Dynamic") }
        Mock Get-CimInstance { @() }
        Mock Invoke-WPFtweaksbutton { $null = $script:calls.Add("Tweaks") }
        Mock Invoke-WPFInstall { $null = $script:calls.Add("Install") }
        Mock Invoke-WPFFeatureInstall { $null = $script:calls.Add("Features") }
        Mock Invoke-WPFAppxRemoval { $null = $script:calls.Add("AppX") }
        Mock Invoke-WPFButton { param($Button) $null = $script:calls.Add($Button) }
        Mock Show-WinUtilMessage { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name calls -Scope Script -ErrorAction SilentlyContinue
    }

    Context "XAML" {
        It "defines the chooser, decision card, app picker, review and seven dots" {
            $names = @($script:xaml.SelectNodes("//*[@Name]") | ForEach-Object { $_.GetAttribute("Name") })
            $required = @(
                "WPFModeSelectionOverlay", "WPFModeSetupButton", "WPFModeAdvancedButton", "WPFModeCloseButton",
                "WPFGuideCurrentLabel", "WPFGuideTotalLabel",
                "WPFGuidePanel", "WPFGuideCard", "WPFGuideTitle", "WPFGuideDescription",
                "WPFGuideChanges", "WPFGuideBenefits", "WPFGuideInfo", "WPFGuideUndoBadge",
                "WPFGuideWarning", "WPFGuideWarningText", "WPFGuideOptions",
                "WPFGuideOption1", "WPFGuideOption2", "WPFGuideOption3", "WPFGuideOption4",
                "WPFGuideYesButton", "WPFGuideNoButton",
                "WPFGuideAppPanel", "WPFGuideAppSearch", "WPFGuideAppList",
                "WPFGuideSearchPackagesButton", "WPFGuideSearchStatus", "WPFGuidePackageResults", "WPFGuidePackageList",
                "WPFGuideReviewPanel", "WPFGuideSummary",
                "WPFGuideBackButton", "WPFGuideNextButton", "WPFGuideSkipButton", "WPFGuideApplyAllButton",
                "WPFGuideDot1", "WPFGuideDot2", "WPFGuideDot3", "WPFGuideDot4",
                "WPFGuideDot5", "WPFGuideDot6", "WPFGuideDot7"
            )
            @($required | Where-Object { $_ -notin $names }) | Should -BeNullOrEmpty
        }

        It "shows only the chooser on a fresh window" {
            $overlay = $script:xaml.SelectSingleNode("//*[@Name='WPFModeSelectionOverlay']")
            $panel = $script:xaml.SelectSingleNode("//*[@Name='WPFGuidePanel']")
            $overlay.GetAttribute("Visibility") | Should -Be "Visible"
            $panel.GetAttribute("Visibility") | Should -Be "Collapsed"
        }

        It "makes each whole mode card clickable through its named button" {
            foreach ($name in @("WPFModeSetupButton", "WPFModeAdvancedButton")) {
                $button = $script:xaml.SelectSingleNode("//*[@Name='$name']")
                # The template paints a rounded Border with a ContentPresenter, so the whole card is clickable.
                $templateBorder = $button.SelectSingleNode(".//*[local-name()='ControlTemplate']/*[local-name()='Border']")
                $templateBorder | Should -Not -BeNull
                $templateBorder.GetAttribute("CornerRadius") | Should -Be "10"
                $presenter = $button.SelectSingleNode(".//*[local-name()='ContentPresenter']")
                $presenter | Should -Not -BeNull
                # The content holds the texts directly (outside the template) so DynamicResources resolve.
                $contentGrid = $button.SelectSingleNode("./*[local-name()='Grid']")
                $contentGrid | Should -Not -BeNull
                @($contentGrid.SelectNodes(".//*[local-name()='TextBlock']")).Count | Should -BeGreaterOrEqual 3
            }
        }

        It "places the two mode cards side by side in one simple layout" {
            $panel = $script:xaml.SelectSingleNode("//*[@Name='WPFModeSelectionOverlay']//*[local-name()='StackPanel'][@Orientation='Horizontal']")
            $panel | Should -Not -BeNull
            $advanced = $script:xaml.SelectSingleNode("//*[@Name='WPFModeAdvancedButton']")
            $advanced.GetAttribute("Margin") | Should -BeLike "16,0,0,0"
            $setupCard = $script:xaml.SelectSingleNode("//*[@Name='WPFModeSetupButton']")
            [int]$setupCard.GetAttribute("Width") | Should -BeGreaterOrEqual 200
        }

        It "keeps the mode icons left-to-right and simple" {
            $overlay = $script:xaml.SelectSingleNode("//*[@Name='WPFModeSelectionOverlay']")
            $icons = @($overlay.SelectNodes(".//*[local-name()='TextBlock'][@FontFamily='Segoe MDL2 Assets']"))
            $icons.Count | Should -BeGreaterOrEqual 2
            foreach ($icon in $icons) {
                $icon.GetAttribute("FlowDirection") | Should -Be "LeftToRight"
            }
            # No complex animations or transforms on the cards
            @($overlay.SelectNodes(".//*[local-name()='EventTrigger']")).Count | Should -Be 0
            @($overlay.SelectNodes(".//*[local-name()='Storyboard']")).Count | Should -Be 0
        }

        It "uses equal-sized side-by-side cards with no badge text" {
            $setupCard = $script:xaml.SelectSingleNode("//*[@Name='WPFModeSetupButton']")
            $advanced = $script:xaml.SelectSingleNode("//*[@Name='WPFModeAdvancedButton']")
            $setupCard.GetAttribute("Width") | Should -Be $advanced.GetAttribute("Width")
            $setupCard.GetAttribute("Height") | Should -Be $advanced.GetAttribute("Height")
            # No "Recommended" badge elements remain.
            @($script:xaml.SelectNodes("//*[contains(@Name,'Recommended')]")).Count | Should -Be 0
        }

        It "shares one border colour and one icon colour across both cards" {
            $setupCard = $script:xaml.SelectSingleNode("//*[@Name='WPFModeSetupButton']")
            $advanced = $script:xaml.SelectSingleNode("//*[@Name='WPFModeAdvancedButton']")
            $setupCard.GetAttribute("BorderBrush") | Should -Be $advanced.GetAttribute("BorderBrush")
            $setupIcon = $setupCard.SelectSingleNode(".//*[local-name()='TextBlock'][@FontFamily='Segoe MDL2 Assets']")
            $advancedIcon = $advanced.SelectSingleNode(".//*[local-name()='TextBlock'][@FontFamily='Segoe MDL2 Assets']")
            $setupIcon.GetAttribute("Foreground") | Should -Be $advancedIcon.GetAttribute("Foreground")
        }

        It "animates the checkbox tick on and off" {
            $cb = Get-Content (Join-Path $script:repoRoot "xaml\src\resources\Toggles\CheckBox.xaml") -Raw
            $cb | Should -Match 'BeginStoryboard Name="TickDraw"'
            $cb | Should -Match 'BeginStoryboard Name="TickErase"'
            $cb | Should -Match 'StrokeDashOffset'
            $cb | Should -Match 'DataTrigger.ExitActions'
        }

        It "uses a circular checkbox style on application cards" {
            $ns = New-Object System.Xml.XmlNamespaceManager($script:xaml.NameTable)
            $ns.AddNamespace("x", "http://schemas.microsoft.com/winfx/2006/xaml")
            $style = $script:xaml.SelectSingleNode("//*[@x:Key='GuideCircularCheckBox']", $ns)
            $style | Should -Not -BeNull
            $mark = $style.SelectSingleNode('.//*[local-name()="TextBlock"][@Name="GuideMark"]')
            $mark | Should -Not -BeNull
            $mark.GetAttribute("Text") | Should -Be ([string][char]0xE73E)
        }
    }

    Context "Mode selection" {
        It "keeps the original tabs in Advanced mode" {
            Set-WinUtilUiMode -Mode "Advanced"

            $script:sync.UiMode | Should -Be "Advanced"
            $script:sync.WPFModeSelectionOverlay.Visibility | Should -Be "Collapsed"
            $script:sync.NavDockPanel.Visibility | Should -Be "Visible"
            $script:sync.WPFTabNav.Visibility | Should -Be "Visible"
            $script:sync.WPFGuidePanel.Visibility | Should -Be "Collapsed"
            Should -Invoke Invoke-WPFTab -Times 1 -Exactly -ParameterFilter { $ClickedTab -eq "WPFTab1BT" }
        }

        It "starts the wizard on step one with defaults and app cards in Setup mode" {
            Set-WinUtilUiMode -Mode "Setup"

            $script:sync.UiMode | Should -Be "Setup"
            $script:sync.NavDockPanel.Visibility | Should -Be "Collapsed"
            $script:sync.WPFTabNav.Visibility | Should -Be "Collapsed"
            $script:sync.WPFGuidePanel.Visibility | Should -Be "Visible"
            $script:sync.GuideStep | Should -Be 1
            $script:sync.GuideStepName | Should -Be "RestorePoint"
            $script:sync.GuideChoices["RestorePoint"] | Should -BeTrue
            $script:sync.GuideChoices["Updates"] | Should -Be "Keep"
            $script:sync.GuideIsLaptop | Should -BeFalse
            $script:sync.WPFGuideAppList.Children.Count | Should -Be 2
            $script:sync.WPFGuideCard.Visibility | Should -Be "Visible"
        }

        It "builds categorized app cards with icon plates and tick checkboxes" {
            Set-WinUtilUiMode -Mode "Setup"

            $script:sync.GuideAppCards.Count | Should -Be 2
            $script:sync.GuideAppCategories.Count | Should -Be 1
            $script:sync.GuideAppCategories[0].Category | Should -Be "Other"
            foreach ($card in $script:sync.GuideAppCards) {
                $card.Border | Should -BeOfType ([System.Windows.Controls.Border])
                $check = $card.Border.Child.Children[0]
                $check | Should -BeOfType ([System.Windows.Controls.CheckBox])
                $check.Content.Children[0] | Should -BeOfType ([System.Windows.Controls.Border])
            }
        }

        It "filters app cards by search text" {
            Set-WinUtilUiMode -Mode "Setup"

            Set-WinUtilGuideAppFilter -Text "curl"
            $visible = @($script:sync.GuideAppCards | Where-Object { $_.Border.Visibility -ne "Collapsed" })
            $visible.Count | Should -Be 1
            $visible[0].Key | Should -Be "WPFInstallcurl"

            Set-WinUtilGuideAppFilter -Text ""
            @($script:sync.GuideAppCards | Where-Object { $_.Border.Visibility -ne "Collapsed" }).Count | Should -Be 2
        }
    }

    Context "Step navigation" {
        It "records a Yes decision and advances" {
            Set-WinUtilUiMode -Mode "Setup"

            Set-WinUtilGuideChoice -Choice "No"

            $script:sync.GuideChoices["RestorePoint"] | Should -BeFalse
            $script:sync.GuideStep | Should -Be 2
            $script:sync.GuideStepName | Should -Be "Install"
            $script:sync.WPFGuideCard.Visibility | Should -Be "Collapsed"
            $script:sync.WPFGuideAppPanel.Visibility | Should -Be "Visible"
        }

        It "marks a step skipped and keeps it out of the summary actions" {
            Set-WinUtilUiMode -Mode "Setup"
            Set-WinUtilGuideChoice -Choice "Yes"
            Set-WinUtilGuideStepSkipped

            $script:sync.GuideSkipped.Contains("Install") | Should -BeTrue
            $script:sync.GuideStepName | Should -Be "Tweaks"
            Get-WinUtilGuideSummary | Should -Match "Install : Skipped"
        }

        It "moves back and forward and stops at the ends" {
            Set-WinUtilUiMode -Mode "Setup"
            Move-WinUtilGuideStep -Direction "Previous"
            $script:sync.GuideStep | Should -Be 1
            Move-WinUtilGuideStep -Direction "Next"
            $script:sync.GuideStep | Should -Be 2
        }

        It "records an option choice without leaving the step" {
            Set-WinUtilUiMode -Mode "Setup"
            Set-WinUtilGuideStep -Step 3
            $script:sync.WPFGuideOption2.Tag = "Standard"

            Set-WinUtilGuideOption -Index 2

            $script:sync.GuideChoices["Tweaks"] | Should -Be "Standard"
            $script:sync.GuideStep | Should -Be 3
        }

        It "shows the battery warning only when a battery is detected" {
            Set-WinUtilUiMode -Mode "Setup"
            Set-WinUtilGuideStep -Step 6
            $script:sync.GuideIsLaptop = $false
            Set-WinUtilGuideStep -Step 6
            $script:sync.WPFGuideWarning.Visibility | Should -Be "Collapsed"

            $script:sync.GuideIsLaptop = $true
            Set-WinUtilGuideStep -Step 6
            $script:sync.WPFGuideWarning.Visibility | Should -Be "Visible"
            $script:sync.WPFGuideWarningText.Text | Should -Match "portable"
        }

        It "shows card content again after the Advanced tab steps" {
            Set-WinUtilUiMode -Mode "Setup"

            Set-WinUtilGuideStep -Step 3
            $script:sync.WPFTabNav.Visibility | Should -Be "Visible"
            $script:sync.WPFGuidePanel.Visibility | Should -Be "Collapsed"
            $script:sync.WPFTweaksbutton.Visibility | Should -Be "Collapsed"

            Set-WinUtilGuideStep -Step 5
            $script:sync.WPFTabNav.Visibility | Should -Be "Collapsed"
            $script:sync.WPFGuidePanel.Visibility | Should -Be "Visible"
            $script:sync.WPFGuideCard.Visibility | Should -Be "Visible"

            Set-WinUtilGuideStep -Step 6
            $script:sync.WPFGuideCard.Visibility | Should -Be "Visible"

            Set-WinUtilGuideStep -Step 7
            $script:sync.WPFGuideReviewPanel.Visibility | Should -Be "Visible"
        }

        It "shows the power option in Config and restores Run Tweaks in Advanced" {
            Set-WinUtilUiMode -Mode "Setup"
            $script:sync.InitializedTabs["Config"] = $true
            Set-WinUtilGuideStep -Step 4
            $script:sync.WPFGuidePowerPanel.Visibility | Should -Be "Visible"
            $script:sync.selectedFeatures | Should -Be @("WPFFeaturesdotnet")
            $script:sync.InitializedTabs["Config"] | Should -BeFalse

            Set-WinUtilUiMode -Mode "Advanced"
            $script:sync.WPFGuidePowerPanel.Visibility | Should -Be "Collapsed"
            $script:sync.WPFTweaksbutton.Visibility | Should -Be "Visible"
        }

        It "hides Legacy Windows Panels from the guided Config step" {
            $renderer = Get-Content -Path (Join-Path $script:repoRoot "functions\public\Invoke-WPFUIElements.ps1") -Raw
            $renderer | Should -Match 'UiMode -eq "Setup" -and \$category -like "\*Legacy Windows Panels\*"'
        }
    }

    Context "Package search" {
        It "parses winget and Chocolatey results into selectable packages" {
            Mock winget { "Name                 Id                 Version"; "7-Zip                7zip.7zip          26.06" }
            Mock choco { "7zip|26.06" }
            Mock Get-WinUtilPackageIconUrl { return $null }

            $found = @(Search-WinUtilPackages -Query "zip")

            $found.Count | Should -Be 2
            $found[0].Source | Should -Be "winget"
            $found[0].Id | Should -Be "7zip.7zip"
            $found[1].Source | Should -Be "chocolatey"
            $found[1].Id | Should -Be "7zip"
        }

        It "installs searched packages at the end of the run" {
            Set-WinUtilUiMode -Mode "Setup"
            $script:sync.GuideDynamicPackages.Add([pscustomobject]@{ Source = "winget"; Id = "Foo.Bar"; Name = "Foo" })

            Invoke-WinUtilGuideApplyAll

            $script:calls.ToArray() | Should -Be @("Tweaks", "Dynamic")
        }
    }

    Context "Review and apply" {
        It "summarises the choices on the review step" {
            Set-WinUtilUiMode -Mode "Setup"
            Set-WinUtilGuideStep -Step 7

            $script:sync.WPFTabNav.Visibility | Should -Be "Collapsed"
            $script:sync.WPFGuideReviewPanel.Visibility | Should -Be "Visible"
            $script:sync.WPFGuideSummary.Text | Should -Match "Restore point : Yes"
            $script:sync.WPFGuideSummary.Text | Should -Match "Tweaks : None"
            $script:sync.WPFGuideSummary.Text | Should -Match "Windows Update Profiles : Keep current"
        }

        It "queues the accepted actions in the safety-first order" {
            Set-WinUtilUiMode -Mode "Setup"
            $script:sync.GuideChoices["RestorePoint"] = $true
            $script:sync.GuideChoices["Tweaks"] = "Standard"
            $script:sync.GuideChoices["AppX"] = $true
            $script:sync.GuideChoices["Updates"] = "Recommended"
            $script:sync.selectedApps.Add("WPFInstall7zip")
            $script:sync.selectedFeatures = @("WPFFeaturesdotnet")
            $script:sync.WPFGuideHighPerformance.IsChecked = $true

            Invoke-WinUtilGuideApplyAll

            $script:calls.ToArray() | Should -Be @("Tweaks", "Install", "Features", "HighPerformance", "AppX", "WPFUpdatessecurity")
            $script:sync.selectedTweaks[0] | Should -Be "WPFTweaksRestorePoint"
            $script:sync.selectedAppx | Should -Be @("WPFAppxFoo")
        }

        It "does not apply a skipped step" {
            Set-WinUtilUiMode -Mode "Setup"
            [void]$script:sync.GuideSkipped.Add("AppX")
            $script:sync.GuideChoices["AppX"] = $true

            Invoke-WinUtilGuideApplyAll

            $script:calls.ToArray() | Should -Be @("Tweaks")
        }

        It "routes every guide button" {
            $source = Get-Content -Path $script:buttonScript -Raw
            $names = @(
                "WPFModeSetupButton", "WPFModeAdvancedButton", "WPFModeCloseButton",
                "WPFGuideBackButton", "WPFGuideNextButton", "WPFGuideSkipButton",
                "WPFGuideYesButton", "WPFGuideNoButton", "WPFGuideOption1", "WPFGuideOption2",
                "WPFGuideOption3", "WPFGuideOption4", "WPFGuideApplyAllButton"
            )
            foreach ($name in $names) {
                $source | Should -Match ([regex]::Escape("`"$name`""))
            }
        }
    }
}
