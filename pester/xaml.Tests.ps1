#===========================================================================
# Tests - XAML Control Wiring
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:configRoot = Join-Path $script:repoRoot "config"
    $script:functionRoot = Join-Path $script:repoRoot "functions"
    $script:scriptsRoot = Join-Path $script:repoRoot "scripts"
    $script:xamlPath = Join-Path $script:repoRoot "xaml\inputXML.xaml"
    $script:mainScriptPath = Join-Path $script:scriptsRoot "main.ps1"
    $script:buttonScriptPath = Join-Path $script:functionRoot "public\Invoke-WPFButton.ps1"
    $script:xamlText = Get-Content -Path $script:xamlPath -Raw
    $script:xaml = [xml]$script:xamlText
    $script:xamlNamespace = New-Object System.Xml.XmlNamespaceManager -ArgumentList $script:xaml.NameTable
    $script:xamlNamespace.AddNamespace("x", "http://schemas.microsoft.com/winfx/2006/xaml")

    function script:Get-WinUtilConfigObject {
        param([string]$Name)

        Get-Content -Path (Join-Path $script:configRoot "$Name.json") -Raw | ConvertFrom-Json
    }

    function script:Get-WinUtilSourceText {
        Get-ChildItem -Path @($script:functionRoot, $script:scriptsRoot) -Filter *.ps1 -Recurse |
            ForEach-Object { Get-Content -Path $_.FullName -Raw } |
            Out-String
    }

    function script:Get-WinUtilTopLevelFunctionNames {
        Get-ChildItem -Path $script:functionRoot -Filter *.ps1 -Recurse | ForEach-Object {
            $tokens = $null
            $syntaxErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$syntaxErrors)
            if ($syntaxErrors.Count -ne 0) {
                throw ($syntaxErrors | Out-String)
            }

            $ast.EndBlock.Statements |
                Where-Object { $_ -is [System.Management.Automation.Language.FunctionDefinitionAst] } |
                ForEach-Object { $_.Name }
        } | Sort-Object -Unique
    }

    function script:Get-WinUtilXamlNamedControls {
        $nodes = $script:xaml.SelectNodes("//*[@Name or @x:Name]", $script:xamlNamespace)
        foreach ($node in $nodes) {
            $controlName = $node.GetAttribute("Name")
            if ([string]::IsNullOrWhiteSpace($controlName)) {
                $controlName = $node.GetAttribute("Name", "http://schemas.microsoft.com/winfx/2006/xaml")
            }

            [pscustomobject]@{
                Name = $controlName
                Type = $node.LocalName
            }
        }
    }

    function script:Get-WinUtilXamlRuntimeNamedControls {
        $nodes = $script:xaml.SelectNodes("//*[@Name]")
        foreach ($node in $nodes) {
            [pscustomobject]@{
                Name = $node.GetAttribute("Name")
                Type = $node.LocalName
            }
        }
    }

    function script:Get-WinUtilGeneratedControlNames {
        $names = New-Object System.Collections.Generic.List[string]
        foreach ($configName in @("appnavigation", "tweaks", "feature", "appx")) {
            $config = Get-WinUtilConfigObject -Name $configName
            foreach ($entry in $config.PSObject.Properties.Name) {
                $names.Add($entry)
            }
        }

        $applications = Get-WinUtilConfigObject -Name "applications"
        foreach ($entry in $applications.PSObject.Properties.Name) {
            $names.Add($entry)
            $names.Add(($entry -replace "-", "_"))
        }

        $names | Sort-Object -Unique
    }

    function script:Get-WinUtilButtonSwitchNames {
        $buttonSource = Get-Content -Path $script:buttonScriptPath -Raw
        [regex]::Matches($buttonSource, '"(WPF[A-Za-z0-9_]+)"\s*\{') |
            ForEach-Object { $_.Groups[1].Value } |
            Sort-Object -Unique
    }

    function script:Test-WinUtilNameInSet {
        param(
            [Parameter(Mandatory)]
            [string]$Name,

            [Parameter(Mandatory)]
            [string[]]$Set
        )

        foreach ($item in $Set) {
            if ($item -ieq $Name) {
                return $true
            }
        }

        return $false
    }
}

Describe "XAML document" {
    It "loads inputXML.xaml as a WPF window XML document" {
        $script:xaml.DocumentElement.LocalName | Should -Be "Window"
    }

    It "contains expected core controls" {
        $xamlNames = @(Get-WinUtilXamlRuntimeNamedControls | ForEach-Object { $_.Name })
        $requiredControls = @(
            "WPFMainGrid",
            "NavDockPanel",
            "GridBesideNavDockPanel",
            "WPFTabNav",
            "WPFTab1",
            "WPFTab2",
            "WPFTab3",
            "WPFTab4",
            "WPFTab5",
            "WPFTab6",
            "WPFTab1BT",
            "WPFTab2BT",
            "WPFTab3BT",
            "WPFTab4BT",
            "WPFTab5BT",
            "SearchBar",
            "SearchBarIcon",
            "SearchBarClearButton",
            "WPFSearchChips",
            "WPFSearchChipAll",
            "WPFSearchChipBrowsers",
            "WPFSearchChipCommunications",
            "WPFSearchChipDevelopment",
            "WPFSearchChipGames",
            "WPFSearchChipMicrosoftTools",
            "WPFSearchChipMultimediaTools",
            "WPFSearchChipProTools",
            "WPFSearchChipSelfhostedTools",
            "WPFSearchChipUtilities",
            "appscategory",
            "appspanel",
            "tweakspanel",
            "featurespanel",
            "appxpanel",
            "WPFstandard",
            "WPFminimal",
            "WPFAdvanced",
            "WPFClearTweaksSelection",
            "WPFGetInstalledTweaks",
            "WPFAppxRemoval",
            "WPFTweaksbutton",
            "WPFUndoall",
            "WPFUpdatesdefault",
            "WPFUpdatessecurity",
            "WPFUpdatesdisable",
            "WPFDefaultAppxSelection",
            "WPFGetInstalledAppx",
            "WPFSelectAllAppx",
            "WPFClearAppxSelection",
            "WPFBackToTweaks",
            "WPFInstallSelectedAppx",
            "WPFRemoveSelectedAppx"
        )

        $missingControls = @($requiredControls | Where-Object { -not (Test-WinUtilNameInSet -Name $_ -Set $xamlNames) })
        if ($missingControls.Count -gt 0) {
            throw ($missingControls -join "`n")
        }
    }

    It "presents the three Updates profiles with accurate action labels" {
        $updatesTab = $script:xaml.SelectSingleNode('//*[local-name()="TabItem"][@Name="WPFTab4"]')
        $profileGrid = $updatesTab.SelectSingleNode('.//*[local-name()="UniformGrid"]')
        $expectedButtons = @{
            WPFUpdatessecurity = "Apply Recommended"
            WPFUpdatesdefault = "Restore Defaults"
            WPFUpdatesdisable = "Disable Updates"
        }

        $profileGrid.GetAttribute("Columns") | Should -Be "3"
        foreach ($buttonName in $expectedButtons.Keys) {
            $button = $updatesTab.SelectSingleNode(".//*[local-name()='Button'][@Name='$buttonName']")
            $button.GetAttribute("Content") | Should -Be $expectedButtons[$buttonName]
        }
        $updatesTab.SelectSingleNode('.//*[@Name="updatespanel"]') | Should -BeNullOrEmpty
    }

    It "contains Win11 Creator controls used by the ISO workflow" {
        $xamlNames = @(Get-WinUtilXamlRuntimeNamedControls | ForEach-Object { $_.Name })
        $requiredControls = @(
            "Win11ISOPanel",
            "WPFWin11ISOSelectSection",
            "WPFWin11ISOPath",
            "WPFWin11ISOBrowseButton",
            "WPFWin11ISOFileInfo",
            "WPFWin11ISODownloadLink",
            "WPFWin11ISOMountSection",
            "WPFWin11ISOMountButton",
            "WPFWin11ISOInjectDrivers",
            "WPFWin11ISOVerifyResultPanel",
            "WPFWin11ISOMountDriveLetter",
            "WPFWin11ISOArchLabel",
            "WPFWin11ISOEditionComboBox",
            "WPFWin11ISOModifySection",
            "WPFWin11ISOModifyButton",
            "WPFWin11ISOOutputSection",
            "WPFWin11ISOCleanResetButton",
            "WPFWin11ISOChooseISOButton",
            "WPFWin11ISOChooseUSBButton",
            "WPFWin11ISOOptionUSB",
            "WPFWin11ISOUSBDriveComboBox",
            "WPFWin11ISORefreshUSBButton",
            "WPFWin11ISOWriteUSBButton",
            "WPFWin11ISOStatusLog"
        )

        $missingControls = @($requiredControls | Where-Object { -not (Test-WinUtilNameInSet -Name $_ -Set $xamlNames) })
        if ($missingControls.Count -gt 0) {
            throw ($missingControls -join "`n")
        }
    }

    It "defines core tabs in the expected order" {
        $tabItems = @($script:xaml.SelectNodes('//*[local-name()="TabControl"][@Name="WPFTabNav"]/*[local-name()="TabItem"]'))
        $actualTabs = @($tabItems | ForEach-Object { "$($_.GetAttribute("Name")):$($_.GetAttribute("Header"))" })
        $expectedTabs = @(
            "WPFTab1:Install",
            "WPFTab2:Tweaks",
            "WPFTab3:Config",
            "WPFTab4:Updates",
            "WPFTab5:Win11ISO",
            "WPFTab6:AppX"
        )

        if (@($actualTabs).Count -ne $expectedTabs.Count) {
            throw "Expected $($expectedTabs.Count) tabs but found $(@($actualTabs).Count): $($actualTabs -join ', ')"
        }

        for ($index = 0; $index -lt $expectedTabs.Count; $index++) {
            if ($actualTabs[$index] -ne $expectedTabs[$index]) {
                throw "Tab order mismatch at index ${index}: expected $($expectedTabs[$index]), found $($actualTabs[$index])"
            }
        }
    }

    It "opens AppX removal from Tweaks and provides a return path" {
        $navPanel = $script:xaml.SelectSingleNode('//*[local-name()="StackPanel"][@Name="NavDockPanel"]')
        $tweaksTab = $script:xaml.SelectSingleNode('//*[local-name()="TabItem"][@Name="WPFTab2"]')
        $appxTab = $script:xaml.SelectSingleNode('//*[local-name()="TabItem"][@Name="WPFTab6"]')
        $openButton = $tweaksTab.SelectSingleNode('.//*[local-name()="Button"][@Name="WPFAppxRemoval"]')
        $buttonNames = @($openButton.ParentNode.SelectNodes('./*[local-name()="Button"]') | ForEach-Object { $_.GetAttribute("Name") })
        $getInstalledIndex = [array]::IndexOf($buttonNames, "WPFGetInstalledTweaks")
        $openAppxIndex = [array]::IndexOf($buttonNames, "WPFAppxRemoval")
        $buttonSource = Get-Content -Path $script:buttonScriptPath -Raw
        $tabSource = Get-Content -Path (Join-Path $script:functionRoot "public\Invoke-WPFTab.ps1") -Raw

        $navPanel.SelectSingleNode('./*[local-name()="ToggleButton"][@Name="WPFTab6BT"]') | Should -BeNullOrEmpty
        $openButton.GetAttribute("Content").Trim() | Should -Be "AppX Removal"
        $openAppxIndex | Should -Be ($getInstalledIndex + 1)
        $appxTab.SelectSingleNode('.//*[local-name()="Button"][@Name="WPFBackToTweaks"]') | Should -Not -BeNullOrEmpty
        $appxTab.SelectSingleNode('.//*[local-name()="Button"][@Name="WPFInstallSelectedAppx"]') | Should -Not -BeNullOrEmpty
        $appxTab.SelectSingleNode('.//*[local-name()="Button"][@Name="WPFRemoveSelectedAppx"]') | Should -Not -BeNullOrEmpty
        $buttonSource | Should -Match '"WPFAppxRemoval"\s*\{Invoke-WPFTab "WPFTab6BT"\}'
        $buttonSource | Should -Match '"WPFBackToTweaks"\s*\{Invoke-WPFTab "WPFTab2BT"\}'
        $buttonSource | Should -Match '"WPFInstallSelectedAppx"\s*\{Invoke-WPFAppxInstall\}'
        $tabSource | Should -Match '\$sync\.\$tabNav\.Items\[\$tabNumber\]\.IsSelected = \$true'
    }

    It "centers top bar controls vertically" {
        $navPanel = $script:xaml.SelectSingleNode('//*[local-name()="StackPanel"][@Name="NavDockPanel"]')
        $minimizeButton = $script:xaml.SelectSingleNode('//*[local-name()="Button"][@Name="WPFMinimizeButton"]')
        $actionPanel = $minimizeButton.ParentNode
        $topBarButtonNames = @(
            "ThemeButton",
            "FontScalingButton",
            "SettingsButton",
            "WPFMinimizeButton",
            "WPFMaximizeButton",
            "WPFCloseButton"
        )

        $navPanel.GetAttribute("VerticalAlignment") | Should -Be "Center"
        $actionPanel.GetAttribute("VerticalAlignment") | Should -Be "Center"

        foreach ($buttonName in $topBarButtonNames) {
            $button = $script:xaml.SelectSingleNode("//*[local-name()='Button'][@Name='$buttonName']")
            $button.GetAttribute("VerticalAlignment") | Should -Be "Center"
        }
    }

    It "keeps the responsive search controls within the available screen width" {
        $window = $script:xaml.DocumentElement
        $searchBar = $script:xaml.SelectSingleNode('//*[local-name()="TextBox"][@Name="SearchBar"]')
        $searchBorder = $searchBar.ParentNode.ParentNode
        $mainScript = Get-Content -Path $script:mainScriptPath -Raw

        $window.GetAttribute("MinWidth") | Should -Be "800"
        $searchBorder.GetAttribute("Width") | Should -BeNullOrEmpty
        $searchBorder.GetAttribute("HorizontalAlignment") | Should -Be "Stretch"
        $searchBar.GetAttribute("Width") | Should -BeNullOrEmpty
        $searchBar.GetAttribute("HorizontalAlignment") | Should -Be "Stretch"
        $mainScript | Should -Match '\$sync\.Form\.MinWidth = "1150"'
        $mainScript | Should -Match '\$sync\.Form\.MinWidth = \[Math\]::Min\(\[double\]\$sync\.Form\.MinWidth, \[double\]\$screenWidth\)'
    }

    It "shows only one search action glyph at a time" {
        $searchIcon = $script:xaml.SelectSingleNode('//*[local-name()="TextBlock"][@Name="SearchBarIcon"]')
        $clearButton = $script:xaml.SelectSingleNode('//*[local-name()="Button"][@Name="SearchBarClearButton"]')
        $mainScript = Get-Content -Path $script:mainScriptPath -Raw

        $searchIcon | Should -Not -BeNullOrEmpty
        $clearButton | Should -Not -BeNullOrEmpty
        $mainScript | Should -Match '\$sync\.SearchBarClearButton\.Visibility = "Visible"\s+\$sync\.SearchBarIcon\.Visibility = "Collapsed"'
        $mainScript | Should -Match '\$sync\.SearchBarClearButton\.Visibility = "Collapsed"\s+\$sync\.SearchBarIcon\.Visibility = "Visible"'
    }

    It "scopes toggle button styles without leaking into combo boxes" {
        $resources = $script:xaml.SelectSingleNode('//*[local-name()="Window.Resources"]')
        $implicitToggleStyles = @($resources.SelectNodes('./*[local-name()="Style"][@TargetType="ToggleButton" or @TargetType="{x:Type ToggleButton}"][not(@x:Key)]', $script:xamlNamespace))
        $tabStyle = $resources.SelectSingleNode('./*[local-name()="Style"][@x:Key="TabToggleButton"]', $script:xamlNamespace)
        $comboToggleStyle = $resources.SelectSingleNode('./*[local-name()="Style"][@x:Key="ComboBoxToggleButtonStyle"]', $script:xamlNamespace)
        $comboStyle = $resources.SelectSingleNode('./*[local-name()="Style"][@TargetType="ComboBox"]')
        $comboToggle = $comboStyle.SelectSingleNode('.//*[local-name()="ToggleButton"][@Name="ToggleButton"]')
        $comboItemStyle = $resources.SelectSingleNode('./*[local-name()="Style"][@TargetType="ComboBoxItem"]')
        $navButtons = @($script:xaml.SelectNodes('//*[local-name()="StackPanel"][@Name="NavDockPanel"]/*[local-name()="ToggleButton"]'))

        $implicitToggleStyles | Should -BeNullOrEmpty
        $tabStyle | Should -Not -BeNullOrEmpty
        $comboToggleStyle | Should -Not -BeNullOrEmpty
        $comboToggle.GetAttribute("Style") | Should -Be "{StaticResource ComboBoxToggleButtonStyle}"
        $comboItemStyle | Should -Not -BeNullOrEmpty
        $navButtons.Count | Should -Be 5
        foreach ($navButton in $navButtons) {
            $navButton.GetAttribute("Style") | Should -Be "{StaticResource TabToggleButton}"
        }
    }

    It "uses state-aware maximize and restore icons" {
        $themes = Get-WinUtilConfigObject -Name "themes"
        $minimizeButton = $script:xaml.SelectSingleNode('//*[local-name()="Button"][@Name="WPFMinimizeButton"]')
        $maximizeButton = $script:xaml.SelectSingleNode('//*[local-name()="Button"][@Name="WPFMaximizeButton"]')
        $closeButton = $script:xaml.SelectSingleNode('//*[local-name()="Button"][@Name="WPFCloseButton"]')
        $maximizeStyle = $maximizeButton.SelectSingleNode('./*[local-name()="Button.Style"]/*[local-name()="Style"]')
        $maximizeIcon = $maximizeStyle.SelectSingleNode('./*[local-name()="Setter"][@Property="Content"]')
        $maximizedTrigger = $maximizeStyle.SelectSingleNode('./*[local-name()="Style.Triggers"]/*[local-name()="DataTrigger"][@Value="Maximized"]')
        $restoreIcon = $maximizedTrigger.SelectSingleNode('./*[local-name()="Setter"][@Property="Content"]')

        foreach ($button in @($minimizeButton, $maximizeButton, $closeButton)) {
            $button.GetAttribute("FontFamily") | Should -Be "Segoe MDL2 Assets"
            $button.GetAttribute("FontSize") | Should -Be "{DynamicResource CloseIconFontSize}"
            $button.GetAttribute("Margin") | Should -BeIn @("0", "0,0,0,0")
        }

        $minimizeButton.GetAttribute("Content") | Should -Be ([string][char]0xE921)
        $maximizeIcon.GetAttribute("Value") | Should -Be ([string][char]0xE922)
        $restoreIcon.GetAttribute("Value") | Should -Be ([string][char]0xE923)
        $closeButton.GetAttribute("Content") | Should -Be ([string][char]0xE8BB)
        $maximizeStyle.GetAttribute("BasedOn") | Should -Be "{StaticResource HoverButtonStyle}"
        [int]$themes.shared.CloseIconFontSize | Should -BeLessThan ([int]$themes.shared.SettingsIconFontSize)
    }
}

Describe "XAML and sync wiring" {
    It "wires generated config panels to existing target grids" {
        $xamlNames = @(Get-WinUtilXamlRuntimeNamedControls | ForEach-Object { $_.Name })
        $mainLines = Get-Content -Path $script:mainScriptPath
        $invalidTargets = New-Object System.Collections.Generic.List[string]

        foreach ($line in $mainLines) {
            if ($line.TrimStart().StartsWith("#")) {
                continue
            }

            $match = [regex]::Match(
                $line,
                'Invoke-WPFUIElements\s+-configVariable\s+\$sync\.configs\.([A-Za-z0-9_]+)\s+-targetGridName\s+"([^"]+)"'
            )
            if (-not $match.Success) {
                continue
            }

            $configName = $match.Groups[1].Value
            $targetGridName = $match.Groups[2].Value
            if (-not (Test-Path -Path (Join-Path $script:configRoot "$configName.json"))) {
                $invalidTargets.Add("$configName references missing config file")
            }

            if (-not (Test-WinUtilNameInSet -Name $targetGridName -Set $xamlNames)) {
                $invalidTargets.Add("$configName target grid '$targetGridName' was not found in XAML")
            }
        }

        if ($invalidTargets.Count -gt 0) {
            throw ($invalidTargets -join "`n")
        }
    }

    It "references only XAML, generated, or intentionally dynamic sync members" {
        $sourceText = Get-WinUtilSourceText
        $xamlNames = @(Get-WinUtilXamlRuntimeNamedControls | ForEach-Object { $_.Name })
        $generatedNames = @(Get-WinUtilGeneratedControlNames)
        $dynamicStateNames = @(
            "Form",
            "configs",
            "preferences",
            "runspace",
            "Buttons",
            "PSScriptRoot",
            "version",
            "winutildir",
            "logPath",
            "transcriptPath",
            "ProcessRunning",
            "selected",
            "selectedAppx",
            "selectedApps",
            "selectedTweaks",
            "selectedToggles",
            "selectedFeatures",
            "currentTab",
            "selectedAppsStackPanel",
            "selectedAppsstackPanel",
            "selectedAppsPopup",
            "appPopup",
            "appPopupSelectedApp",
            "ItemsControl",
            "InstalledPrograms",
            "ImportInProgress",
            "ScriptsInstallPrograms",
            "keys",
            "ContainsKey",
            "GetEnumerator",
            "Remove",
            "logorender",
            "checkmarkrender",
            "warningrender",
            "InitializedTabs",
            "RenderedAssetCache",
            "ToggleStatusCache",
            "InstallAppRenderQueue",
            "InstallAppEntriesRendered",
            "FontScaleFactor",
            "Win11ISOImageInfo",
            "Win11ISODriveLetter",
            "Win11ISOWimPath",
            "Win11ISOImagePath",
            "Win11ISOModifying",
            "Win11ISOProcessRunning",
            "Win11ISOWorkDir",
            "Win11ISOContentsDir",
            "Win11ISOUSBDisks"
        )
        $allowedNames = @($xamlNames + $generatedNames + $dynamicStateNames) | Sort-Object -Unique
        $bracketReferences = @(
            [regex]::Matches($sourceText, '\$sync\[\s*["'']([A-Za-z_][A-Za-z0-9_]*)["'']\s*\]') |
                ForEach-Object { $_.Groups[1].Value }
        )
        $dotReferences = @(
            [regex]::Matches($sourceText, '\$sync\.([A-Za-z_][A-Za-z0-9_]*)') |
                ForEach-Object { $_.Groups[1].Value }
        )
        $literalReferences = @($bracketReferences + $dotReferences) | Sort-Object -Unique

        $invalidReferences = @(
            $literalReferences | Where-Object { -not (Test-WinUtilNameInSet -Name $_ -Set $allowedNames) }
        )
        if ($invalidReferences.Count -gt 0) {
            throw ($invalidReferences -join "`n")
        }
    }
}

Describe "WPF handler wiring" {
    It "calls only defined Invoke-WPF functions" {
        $sourceText = Get-WinUtilSourceText
        $functionNames = @(Get-WinUtilTopLevelFunctionNames)
        $featureFunctions = @(
            (Get-WinUtilConfigObject -Name "feature").PSObject.Properties |
                Where-Object { $_.Value.function -and $_.Value.function -like "Invoke-WPF*" } |
                ForEach-Object { $_.Value.function }
        )
        $invokedFunctions = @(
            [regex]::Matches($sourceText, '\b(Invoke-WPF[A-Za-z0-9]+)\b') |
                ForEach-Object { $_.Groups[1].Value }
            $featureFunctions
        ) | Sort-Object -Unique

        $missingFunctions = @(
            $invokedFunctions | Where-Object { -not (Test-WinUtilNameInSet -Name $_ -Set $functionNames) }
        )
        if ($missingFunctions.Count -gt 0) {
            throw ($missingFunctions -join "`n")
        }
    }

    It "routes static WPF buttons through Invoke-WPFButton or explicit handlers" {
        $runtimeControls = @(Get-WinUtilXamlRuntimeNamedControls)
        $buttonControls = @(
            $runtimeControls |
                Where-Object { $_.Name -like "WPF*" -and $_.Type -in @("Button", "ToggleButton") }
        )
        $buttonSwitchNames = @(Get-WinUtilButtonSwitchNames)
        $featureNames = @((Get-WinUtilConfigObject -Name "feature").PSObject.Properties.Name)
        $mainScript = Get-Content -Path $script:mainScriptPath -Raw
        $unhandledButtons = New-Object System.Collections.Generic.List[string]

        foreach ($button in $buttonControls) {
            $hasSwitchHandler = (Test-WinUtilNameInSet -Name $button.Name -Set $buttonSwitchNames) -or $button.Name -like "WPFTab?BT"
            $hasFeatureHandler = Test-WinUtilNameInSet -Name $button.Name -Set $featureNames
            $escapedName = [regex]::Escape($button.Name)
            $explicitHandlerPattern = '\$sync\s*(?:\[\s*["'']' + $escapedName + '["'']\s*\]|\.' + $escapedName + ')\.Add_Click'
            $hasExplicitHandler = $mainScript -imatch $explicitHandlerPattern

            if (-not ($hasSwitchHandler -or $hasFeatureHandler -or $hasExplicitHandler)) {
                $unhandledButtons.Add($button.Name)
            }
        }

        if ($unhandledButtons.Count -gt 0) {
            throw ($unhandledButtons -join "`n")
        }
    }

    It "invokes existing WPF button names" {
        $sourceText = Get-WinUtilSourceText
        $xamlNames = @(Get-WinUtilXamlRuntimeNamedControls | ForEach-Object { $_.Name })
        $generatedNames = @(Get-WinUtilGeneratedControlNames)
        $validButtonNames = @($xamlNames + $generatedNames) | Sort-Object -Unique
        $buttonNames = @(
            [regex]::Matches($sourceText, 'Invoke-WPFButton\s+["'']([^"'']+)["'']') |
                ForEach-Object { $_.Groups[1].Value }
        ) | Sort-Object -Unique

        $missingButtons = @(
            $buttonNames | Where-Object { -not (Test-WinUtilNameInSet -Name $_ -Set $validButtonNames) }
        )
        if ($missingButtons.Count -gt 0) {
            throw ($missingButtons -join "`n")
        }
    }
}
