#===========================================================================
# Tests - UI Selection and State Helpers
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    if (-not ("Windows.Visibility" -as [type])) {
        Add-Type @"
namespace Windows
{
    public enum Visibility
    {
        Visible,
        Collapsed
    }
}
"@
    }

    if (-not ("Windows.WindowState" -as [type])) {
        Add-Type @"
namespace Windows
{
    public enum WindowState
    {
        Normal,
        Minimized,
        Maximized
    }
}
"@
    }

    if (-not ("System.Windows.Controls.CheckBox" -as [type])) {
        Add-Type @"
namespace System.Windows.Controls
{
    public class CheckBox
    {
        public bool? IsChecked { get; set; }
    }

    public class Label
    {
        public object Content { get; set; }
    }

    public class WrapPanel
    {
        public object Visibility { get; set; }
    }

    public class StackPanel
    {
        public System.Collections.ArrayList Children { get; private set; }

        public StackPanel()
        {
            Children = new System.Collections.ArrayList();
        }
    }
}
"@
    }

    . (Join-Path $script:repoRoot "functions\private\Update-WinUtilSelections.ps1")
    . (Join-Path $script:repoRoot "functions\private\Reset-WPFCheckBoxes.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFImpex.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFGetInstalled.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFSelectedCheckboxesUpdate.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFButton.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFToggleAllCategories.ps1")

    function Set-WinUtilTweaksProgressIndicator {
        param($Visible, $Label, $Percent)
    }
    function Invoke-WPFRunspace {
        param($ArgumentList, $ParameterList, [scriptblock]$ScriptBlock)
    }
    function Invoke-WPFUIThread {
        param([scriptblock]$ScriptBlock)
    }
    function Invoke-WinUtilCurrentSystem {
        param($CheckBox)
    }
    function Set-WinUtilTaskbaritem {
        param($state)
    }
    function Test-WinUtilPackageManager {
        param([switch]$winget)
    }
    function Write-WinUtilLog {
        param($Message, $Level, $Component)
    }
    function Show-WinUtilMessage {
        param($Message, $Title, $Button, $Icon)
    }

    function script:New-WinUtilFakeCheckBox {
        param([bool]$IsChecked = $false)

        $checkbox = [System.Windows.Controls.CheckBox]::new()
        $checkbox.IsChecked = $IsChecked
        $checkbox
    }

    function script:New-WinUtilFakeCategory {
        param(
            [string]$Label,
            [Windows.Visibility]$Visibility
        )

        $category = [System.Windows.Controls.StackPanel]::new()
        $categoryLabel = [System.Windows.Controls.Label]::new()
        $categoryLabel.Content = $Label
        $wrapPanel = [System.Windows.Controls.WrapPanel]::new()
        $wrapPanel.Visibility = $Visibility

        $null = $category.Children.Add($categoryLabel)
        $null = $category.Children.Add($wrapPanel)

        $category
    }

    function script:New-WinUtilUiStateTestContext {
        $testSync = [Hashtable]::Synchronized(@{
            selectedApps = [System.Collections.Generic.List[string]]::new()
            selectedTweaks = [System.Collections.Generic.List[string]]::new()
            selectedToggles = [System.Collections.Generic.List[string]]::new()
            selectedFeatures = [System.Collections.Generic.List[string]]::new()
            selectedAppx = [System.Collections.Generic.List[string]]::new()
            configs = @{
                applicationsHashtable = @{
                    WPFInstallGit = [pscustomobject]@{
                        Content = "Git"
                    }
                }
                appxHashtable = @{
                    WPFAppxExample = [pscustomobject]@{}
                }
                tweaks = [pscustomobject]@{
                    WPFTweaksTelemetry = [pscustomobject]@{}
                    WPFToggleDarkMode = [pscustomobject]@{}
                }
                feature = [pscustomobject]@{
                    WPFFeatureSandbox = [pscustomobject]@{}
                }
            }
            WPFselectedAppsButton = [pscustomobject]@{
                Content = ""
            }
            selectedAppsstackPanel = [pscustomobject]@{
                Children = [System.Collections.ArrayList]::new()
            }
        })
        $script:sync = $testSync
        $global:sync = $testSync
    }

    function Add-SelectedAppsMenuItem {
        param($name, $key)

        $null = $global:sync.selectedAppsstackPanel.Children.Add([pscustomobject]@{
            Name = $name
            Key = $key
        })
    }
}

Describe "Update-WinUtilSelections" {
    BeforeEach {
        New-WinUtilUiStateTestContext
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
    }

    It "adds imported checkbox keys to the matching selected lists" {
        Update-WinUtilSelections @(
            "WPFInstallGit",
            "WPFTweaksTelemetry",
            "WPFToggleDarkMode",
            "WPFFeatureSandbox",
            "WPFAppxExample"
        )

        @($script:sync.selectedApps) | Should -Be @("WPFInstallGit")
        @($script:sync.selectedTweaks) | Should -Be @("WPFTweaksTelemetry")
        @($script:sync.selectedToggles) | Should -Be @("WPFToggleDarkMode")
        @($script:sync.selectedFeatures) | Should -Be @("WPFFeatureSandbox")
        @($script:sync.selectedAppx) | Should -Be @("WPFAppxExample")
    }

    It "replaces selections only after every imported key is validated" {
        $script:sync.selectedApps.Add("WPFInstallExisting")
        $script:sync.selectedTweaks.Add("WPFTweaksExisting")

        Update-WinUtilSelections -flatJson @(
            "WPFInstallGit",
            "WPFFeatureSandbox"
        ) -Replace

        @($script:sync.selectedApps) | Should -Be @("WPFInstallGit")
        @($script:sync.selectedTweaks) | Should -Be @()
        @($script:sync.selectedFeatures) | Should -Be @("WPFFeatureSandbox")
    }

    It "preserves existing selections when an imported key is unsupported" {
        $script:sync.selectedApps.Add("WPFInstallExisting")
        $script:sync.selectedTweaks.Add("WPFTweaksExisting")

        {
            Update-WinUtilSelections -flatJson @(
                "WPFInstallGit",
                "NotAWinUtilKey"
            ) -Replace
        } | Should -Throw "Unsupported selection key 'NotAWinUtilKey'."

        @($script:sync.selectedApps) | Should -Be @("WPFInstallExisting")
        @($script:sync.selectedTweaks) | Should -Be @("WPFTweaksExisting")
        @($script:sync.selectedFeatures) | Should -Be @()
    }

    It "preserves existing selections when an imported key is not in the current catalog" {
        $script:sync.selectedApps.Add("WPFInstallExisting")

        {
            Update-WinUtilSelections -flatJson @(
                "WPFInstallGit",
                "WPFInstallUnknown"
            ) -Replace
        } | Should -Throw "Unknown selection key 'WPFInstallUnknown'."

        @($script:sync.selectedApps) | Should -Be @("WPFInstallExisting")
        @($script:sync.selectedTweaks) | Should -Be @()
        @($script:sync.selectedFeatures) | Should -Be @()
    }
}

Describe "Invoke-WPFImpex import selection state" {
    BeforeEach {
        New-WinUtilUiStateTestContext
        $script:sync.Form = [pscustomobject]@{}

        Mock Reset-WPFCheckBoxes { }
        Mock Write-Error { }
        Mock Write-WinUtilLog { }
        Mock Show-WinUtilMessage { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
    }

    It "replaces selections and resets the UI after a valid import" {
        $script:sync.selectedApps.Add("WPFInstallExisting")
        $script:sync.selectedTweaks.Add("WPFTweaksExisting")
        $configPath = Join-Path $TestDrive "valid-config.json"
        @(
            "WPFInstallGit",
            "WPFFeatureSandbox"
        ) | ConvertTo-Json | Set-Content -LiteralPath $configPath

        Invoke-WPFImpex -type "import" -Config $configPath

        @($script:sync.selectedApps) | Should -Be @("WPFInstallGit")
        @($script:sync.selectedTweaks) | Should -Be @()
        @($script:sync.selectedFeatures) | Should -Be @("WPFFeatureSandbox")
        Should -Invoke -CommandName Reset-WPFCheckBoxes -Times 1 -Exactly -ParameterFilter {
            $doToggles -eq $true
        }
        Should -Invoke -CommandName Write-Error -Times 0 -Exactly
    }

    It "imports supported legacy selections and reports retired entries" {
        $configPath = Join-Path $script:repoRoot "pester\fixtures\legacy-config.json"

        Invoke-WPFImpex -type "import" -Config $configPath

        @($script:sync.selectedApps) | Should -Be @("WPFInstallGit")
        @($script:sync.selectedTweaks) | Should -Be @("WPFTweaksTelemetry")
        @($script:sync.selectedFeatures) | Should -Be @("WPFFeatureSandbox")
        Should -Invoke -CommandName Reset-WPFCheckBoxes -Times 1 -Exactly -ParameterFilter {
            $doToggles -eq $true
        }
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Component -eq "Impex" -and
            $Level -eq "WARN" -and
            $Message -eq "Skipped unsupported legacy selections: WPFInstallRetired"
        }
        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Title -eq "Legacy Configuration Partially Imported" -and
            $Message -like "*WPFInstallRetired*"
        }
        Should -Invoke -CommandName Write-Error -Times 0 -Exactly
    }

    It "ignores unrelated string metadata in a legacy configuration" {
        $configPath = Join-Path $TestDrive "legacy-config-with-metadata.json"
        [pscustomobject]@{
            Install = @([pscustomobject]@{ winget = "Git.Git"; choco = "git" })
            WPFInstall = @("WPFInstallGit")
            ExportVersion = "1.0"
        } | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $configPath

        Invoke-WPFImpex -type "import" -Config $configPath

        @($script:sync.selectedApps) | Should -Be @("WPFInstallGit")
        Should -Invoke -CommandName Reset-WPFCheckBoxes -Times 1 -Exactly
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Component -eq "Impex" -and
            $Message -eq "Detected legacy WinUtil config structure; flattening import object."
        }
        Should -Invoke -CommandName Show-WinUtilMessage -Times 0 -Exactly
        Should -Invoke -CommandName Write-Error -Times 0 -Exactly
    }

    It "preserves selections when every legacy entry is retired" {
        $script:sync.selectedApps.Add("WPFInstallExisting")
        $configPath = Join-Path $TestDrive "retired-legacy-config.json"
        [pscustomobject]@{
            Install = @([pscustomobject]@{ winget = "Retired.App"; choco = "retired-app" })
            WPFTweaks = @()
            WPFFeature = @()
            WPFInstall = @("WPFInstallRetired")
        } | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $configPath

        Invoke-WPFImpex -type "import" -Config $configPath

        @($script:sync.selectedApps) | Should -Be @("WPFInstallExisting")
        Should -Invoke -CommandName Reset-WPFCheckBoxes -Times 0 -Exactly
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Message -eq "Skipped unsupported legacy selections: WPFInstallRetired"
        }
        Should -Invoke -CommandName Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Title -eq "Unsupported Legacy Configuration"
        }
        Should -Invoke -CommandName Write-Error -Times 0 -Exactly
    }

    It "imports legacy selection groups without treating Install metadata as a selection" {
        $legacyConfigPath = Join-Path $TestDrive "legacy-config.json"
        [ordered]@{
            Install = @(
                [pscustomobject]@{
                    winget = "Git.Git"
                    choco = "git"
                }
            )
            WPFInstall = @("WPFInstallGit")
            WPFTweaks = @("WPFTweaksTelemetry")
            WPFToggle = @("WPFToggleDarkMode")
            WPFFeature = @("WPFFeatureSandbox")
        } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $legacyConfigPath

        Invoke-WPFImpex -type "import" -Config $legacyConfigPath

        @($script:sync.selectedApps) | Should -Be @("WPFInstallGit")
        @($script:sync.selectedTweaks) | Should -Be @("WPFTweaksTelemetry")
        @($script:sync.selectedToggles) | Should -Be @("WPFToggleDarkMode")
        @($script:sync.selectedFeatures) | Should -Be @("WPFFeatureSandbox")
        Should -Invoke -CommandName Write-Error -Times 0 -Exactly
    }

    It "preserves selections and does not reset the UI after an invalid import" {
        $script:sync.selectedApps.Add("WPFInstallExisting")
        $script:sync.selectedTweaks.Add("WPFTweaksExisting")
        $configPath = Join-Path $TestDrive "invalid-config.json"
        @(
            "WPFInstallGit",
            "WPFInstallUnknown"
        ) | ConvertTo-Json | Set-Content -LiteralPath $configPath

        Invoke-WPFImpex -type "import" -Config $configPath

        @($script:sync.selectedApps) | Should -Be @("WPFInstallExisting")
        @($script:sync.selectedTweaks) | Should -Be @("WPFTweaksExisting")
        @($script:sync.selectedFeatures) | Should -Be @()
        Should -Invoke -CommandName Reset-WPFCheckBoxes -Times 0 -Exactly
        Should -Invoke -CommandName Write-Error -Times 1 -Exactly -ParameterFilter {
            $Message -like "An error occurred while importing: *Unknown selection key 'WPFInstallUnknown'.*"
        }
    }
}

Describe "Invoke-WPFSelectedCheckboxesUpdate" {
    BeforeEach {
        New-WinUtilUiStateTestContext
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
    }

    It "adds each checkbox family without duplicating existing selections" {
        Invoke-WPFSelectedCheckboxesUpdate -type "Add" -checkboxName "WPFInstallGit"
        Invoke-WPFSelectedCheckboxesUpdate -type "Add" -checkboxName "WPFInstallGit"
        Invoke-WPFSelectedCheckboxesUpdate -type "Add" -checkboxName "WPFTweaksTelemetry"
        Invoke-WPFSelectedCheckboxesUpdate -type "Add" -checkboxName "WPFToggleDarkMode"
        Invoke-WPFSelectedCheckboxesUpdate -type "Add" -checkboxName "WPFFeatureSandbox"
        Invoke-WPFSelectedCheckboxesUpdate -type "Add" -checkboxName "WPFAppxExample"

        @($script:sync.selectedApps) | Should -Be @("WPFInstallGit")
        @($script:sync.selectedTweaks) | Should -Be @("WPFTweaksTelemetry")
        @($script:sync.selectedToggles) | Should -Be @("WPFToggleDarkMode")
        @($script:sync.selectedFeatures) | Should -Be @("WPFFeatureSandbox")
        @($script:sync.selectedAppx) | Should -Be @("WPFAppxExample")
        $script:sync.WPFselectedAppsButton.Content | Should -Be "Selected Apps: 1"
        $script:sync.selectedAppsstackPanel.Children.Count | Should -Be 1
        $script:sync.selectedAppsstackPanel.Children[0].Key | Should -Be "WPFInstallGit"
    }

    It "removes checkbox keys from the matching selected lists" {
        $script:sync.selectedApps.Add("WPFInstallGit")
        $script:sync.selectedTweaks.Add("WPFTweaksTelemetry")
        $script:sync.selectedToggles.Add("WPFToggleDarkMode")
        $script:sync.selectedFeatures.Add("WPFFeatureSandbox")
        $script:sync.selectedAppx.Add("WPFAppxExample")

        Invoke-WPFSelectedCheckboxesUpdate -type "Remove" -checkboxName "WPFInstallGit"
        Invoke-WPFSelectedCheckboxesUpdate -type "Remove" -checkboxName "WPFTweaksTelemetry"
        Invoke-WPFSelectedCheckboxesUpdate -type "Remove" -checkboxName "WPFToggleDarkMode"
        Invoke-WPFSelectedCheckboxesUpdate -type "Remove" -checkboxName "WPFFeatureSandbox"
        Invoke-WPFSelectedCheckboxesUpdate -type "Remove" -checkboxName "WPFAppxExample"

        $script:sync.selectedApps.Count | Should -Be 0
        $script:sync.selectedTweaks.Count | Should -Be 0
        $script:sync.selectedToggles.Count | Should -Be 0
        $script:sync.selectedFeatures.Count | Should -Be 0
        $script:sync.selectedAppx.Count | Should -Be 0
        $script:sync.WPFselectedAppsButton.Content | Should -Be "Selected Apps: 0"
        $script:sync.selectedAppsstackPanel.Children.Count | Should -Be 0
    }
}

Describe "Invoke-WPFGetInstalled selection state" {
    BeforeEach {
        New-WinUtilUiStateTestContext

        $script:sync.ProcessRunning = $false
        $script:sync.ChocoRadioButton = [pscustomobject]@{ IsChecked = $false }
        $script:sync.preferences = [pscustomobject]@{ packagemanager = "Winget" }
        $script:sync.WPFInstallGit = New-WinUtilFakeCheckBox
        $dispatcher = [pscustomobject]@{}
        $dispatcher | Add-Member -MemberType ScriptMethod -Name BeginInvoke -Value {
            param($Action, [object[]]$Arguments)
            $Action.DynamicInvoke($Arguments)
        }
        $script:sync.Form = [pscustomobject]@{ Dispatcher = $dispatcher }
        $script:capturedGetInstalledScriptBlock = $null
        $script:capturedGetInstalledParameters = @{}

        Mock Test-WinUtilPackageManager { "installed" }
        Mock Invoke-WinUtilCurrentSystem { @("WPFInstallGit") }
        Mock Set-WinUtilTaskbaritem { }
        Mock Write-WinUtilLog { }
        Mock Write-Warning { }
        Mock Invoke-WPFRunspace {
            $script:capturedGetInstalledScriptBlock = $ScriptBlock
            foreach ($parameter in $ParameterList) {
                $script:capturedGetInstalledParameters[$parameter[0]] = $parameter[1]
            }
        }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedGetInstalledScriptBlock -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedGetInstalledParameters -Scope Script -ErrorAction SilentlyContinue
    }

    It "updates the selected app model, checkbox, count, and popup" {
        Invoke-WPFGetInstalled -CheckBox "winget"
        & $script:capturedGetInstalledScriptBlock `
            -checkbox "winget" `
            -managerPreference "Winget" `
            -operation $script:capturedGetInstalledParameters.operation `
            -completeAction $script:capturedGetInstalledParameters.completeAction

        @($script:sync.selectedApps) | Should -Be @("WPFInstallGit")
        $script:sync.WPFInstallGit.IsChecked | Should -BeTrue
        $script:sync.WPFselectedAppsButton.Content | Should -Be "Selected Apps: 1"
        $script:sync.selectedAppsstackPanel.Children.Count | Should -Be 1
        $script:sync.selectedAppsstackPanel.Children[0].Key | Should -Be "WPFInstallGit"
    }

    It "clears the running state when detection fails" {
        Mock Invoke-WinUtilCurrentSystem { throw "detection failed" }

        Invoke-WPFGetInstalled -CheckBox "winget"
        & $script:capturedGetInstalledScriptBlock `
            -checkbox "winget" `
            -managerPreference "Winget" `
            -operation $script:capturedGetInstalledParameters.operation `
            -completeAction $script:capturedGetInstalledParameters.completeAction

        $script:sync.ProcessRunning | Should -BeFalse
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and
                $Component -eq "Install" -and
                $Message -eq "Get installed state failed: detection failed"
        }
        Should -Invoke -CommandName Set-WinUtilTaskbaritem -Times 1 -Exactly -ParameterFilter { $state -eq "None" }
    }

    It "clears the running state when the worker cannot be queued" {
        Mock Invoke-WPFRunspace { throw "queue failed" }

        Invoke-WPFGetInstalled -CheckBox "winget"

        $script:sync.ProcessRunning | Should -BeFalse
        Should -Invoke -CommandName Write-WinUtilLog -Times 1 -Exactly -ParameterFilter {
            $Level -eq "ERROR" -and
                $Component -eq "Install" -and
                $Message -eq "Get installed state failed: queue failed"
        }
        Should -Invoke -CommandName Set-WinUtilTaskbaritem -Times 1 -Exactly -ParameterFilter { $state -eq "None" }
    }
}

Describe "Reset-WPFCheckBoxes" {
    BeforeEach {
        New-WinUtilUiStateTestContext

        $script:sync.selectedApps.Add("WPFInstallGit")
        $script:sync.selectedTweaks.Add("WPFTweaksTelemetry")
        $script:sync.selectedFeatures.Add("WPFFeatureSandbox")
        $script:sync.selectedAppx.Add("WPFAppxExample")
        $script:sync.selectedToggles.Add("WPFToggleDarkMode")

        $script:sync.WPFInstallGit = New-WinUtilFakeCheckBox
        $script:sync.WPFInstallVlc = New-WinUtilFakeCheckBox -IsChecked $true
        $script:sync.WPFTweaksTelemetry = New-WinUtilFakeCheckBox
        $script:sync.WPFFeatureSandbox = New-WinUtilFakeCheckBox
        $script:sync.WPFAppxExample = New-WinUtilFakeCheckBox
        $script:sync.WPFToggleDarkMode = New-WinUtilFakeCheckBox
        $script:sync.WPFToggleOther = New-WinUtilFakeCheckBox -IsChecked $true
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
    }

    It "syncs non-toggle checkboxes from selected lists and updates selected app UI state" {
        Reset-WPFCheckBoxes

        $script:sync.WPFInstallGit.IsChecked | Should -BeTrue
        $script:sync.WPFInstallVlc.IsChecked | Should -BeFalse
        $script:sync.WPFTweaksTelemetry.IsChecked | Should -BeTrue
        $script:sync.WPFFeatureSandbox.IsChecked | Should -BeTrue
        $script:sync.WPFAppxExample.IsChecked | Should -BeTrue
        $script:sync.WPFToggleDarkMode.IsChecked | Should -BeFalse
        $script:sync.WPFselectedAppsButton.Content | Should -Be "Selected Apps: 1"
        $script:sync.selectedAppsstackPanel.Children.Count | Should -Be 1
        $script:sync.selectedAppsstackPanel.Children[0].Name | Should -Be "Git"
        $script:sync.selectedAppsstackPanel.Children[0].Key | Should -Be "WPFInstallGit"
    }

    It "restores imported toggles when requested without changing absent toggles" {
        Reset-WPFCheckBoxes -doToggles $true

        $script:sync.WPFToggleDarkMode.IsChecked | Should -BeTrue
        $script:sync.WPFToggleOther.IsChecked | Should -BeTrue
    }
}

Describe "Invoke-WPFToggleAllCategories" {
    BeforeEach {
        New-WinUtilUiStateTestContext

        $script:sync.ItemsControl = [pscustomobject]@{
            Items = [System.Collections.ArrayList]::new()
        }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
    }

    It "expands all install categories and updates collapsed labels" {
        $category = New-WinUtilFakeCategory -Label "+ Browsers" -Visibility ([Windows.Visibility]::Collapsed)
        $null = $script:sync.ItemsControl.Items.Add($category)

        Invoke-WPFToggleAllCategories -Action "Expand"

        $category.Children[1].Visibility | Should -Be ([Windows.Visibility]::Visible)
        $category.Children[0].Content | Should -Be "- Browsers"
    }

    It "collapses all install categories and updates expanded labels" {
        $category = New-WinUtilFakeCategory -Label "- Browsers" -Visibility ([Windows.Visibility]::Visible)
        $null = $script:sync.ItemsControl.Items.Add($category)

        Invoke-WPFToggleAllCategories -Action "Collapse"

        $category.Children[1].Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $category.Children[0].Content | Should -Be "+ Browsers"
    }

    It "warns and exits when ItemsControl is not initialized" {
        $script:sync.ItemsControl = $null
        Mock Write-Warning { }

        Invoke-WPFToggleAllCategories -Action "Expand"

        Should -Invoke -CommandName Write-Warning -Times 1 -Exactly -ParameterFilter {
            $Message -eq "ItemsControl not initialized"
        }
    }
}

Describe "Invoke-WPFButton progress cleanup" {
    BeforeEach {
        New-WinUtilUiStateTestContext
        Mock Set-WinUtilTweaksProgressIndicator { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
    }

    It "clears completed progress on the next idle button click" {
        $script:sync.ProcessRunning = $false

        Invoke-WPFButton -Button "WPFNoOp"

        Should -Invoke Set-WinUtilTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $false
        }
    }

    It "leaves progress visible while a process is running" {
        $script:sync.ProcessRunning = $true

        Invoke-WPFButton -Button "WPFNoOp"

        Should -Not -Invoke Set-WinUtilTweaksProgressIndicator
    }

    It "leaves progress visible while a Win11 ISO process is running" {
        $script:sync.ProcessRunning = $false
        $script:sync.Win11ISOProcessRunning = $true

        Invoke-WPFButton -Button "WPFNoOp"

        Should -Not -Invoke Set-WinUtilTweaksProgressIndicator
    }
}

