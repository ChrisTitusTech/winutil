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
        public global::Windows.Visibility Visibility { get; set; }
    }

    public class StackPanel
    {
        public System.Collections.ArrayList Children { get; } = new System.Collections.ArrayList();
    }
}
"@
    }

    . (Join-Path $script:repoRoot "functions\private\Update-WinUtilSelections.ps1")
    . (Join-Path $script:repoRoot "functions\private\Reset-WPFCheckBoxes.ps1")
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

        $dispatcher = [pscustomobject]@{}
        $dispatcher | Add-Member -MemberType ScriptMethod -Name Invoke -Value {
            param([scriptblock]$Action)
            & $Action
        }

        $script:sync.ProcessRunning = $false
        $script:sync.ChocoRadioButton = [pscustomobject]@{ IsChecked = $false }
        $script:sync.preferences = [pscustomobject]@{ packagemanager = "Winget" }
        $script:sync.Form = [pscustomobject]@{ Dispatcher = $dispatcher }
        $script:sync.WPFInstallGit = New-WinUtilFakeCheckBox
        $script:capturedGetInstalledScriptBlock = $null

        Mock Test-WinUtilPackageManager { "installed" }
        Mock Invoke-WPFUIThread { }
        Mock Invoke-WinUtilCurrentSystem { @("WPFInstallGit") }
        Mock Invoke-WPFRunspace {
            $script:capturedGetInstalledScriptBlock = $ScriptBlock
            [pscustomobject]@{ MockHandle = $true }
        }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedGetInstalledScriptBlock -Scope Script -ErrorAction SilentlyContinue
    }

    It "updates the selected app model, checkbox, count, and popup" {
        Invoke-WPFGetInstalled -CheckBox "winget"
        & $script:capturedGetInstalledScriptBlock -checkbox "winget" -managerPreference "Winget"

        @($script:sync.selectedApps) | Should -Be @("WPFInstallGit")
        $script:sync.WPFInstallGit.IsChecked | Should -BeTrue
        $script:sync.WPFselectedAppsButton.Content | Should -Be "Selected Apps: 1"
        $script:sync.selectedAppsstackPanel.Children.Count | Should -Be 1
        $script:sync.selectedAppsstackPanel.Children[0].Key | Should -Be "WPFInstallGit"
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

Describe "Invoke-WPFButton window state" {
    BeforeEach {
        New-WinUtilUiStateTestContext
        $script:sync.ProcessRunning = $true
        $script:sync.Form = [pscustomobject]@{
            WindowState = [Windows.WindowState]::Normal
        }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
    }

    It "maximizes a normal window" {
        Invoke-WPFButton -Button "WPFMaximizeButton"

        $script:sync.Form.WindowState | Should -Be ([Windows.WindowState]::Maximized)
    }

    It "restores a maximized window" {
        $script:sync.Form.WindowState = [Windows.WindowState]::Maximized

        Invoke-WPFButton -Button "WPFMaximizeButton"

        $script:sync.Form.WindowState | Should -Be ([Windows.WindowState]::Normal)
    }
}
