#===========================================================================
# Tests - Search and Filter Helpers
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

    public class Thickness
    {
        public double Left { get; set; }
        public double Top { get; set; }
        public double Right { get; set; }
        public double Bottom { get; set; }
        public Thickness(double left, double top, double right, double bottom)
        {
            Left = left;
            Top = top;
            Right = right;
            Bottom = bottom;
        }
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

    public class StackPanel
    {
        public System.Collections.ArrayList Children { get; private set; }
        public object Orientation { get; set; }
        public object HorizontalAlignment { get; set; }
        public object Tag { get; set; }
        public object Margin { get; set; }
        public object Visibility { get; set; }

        public StackPanel()
        {
            Children = new System.Collections.ArrayList();
        }
    }

    public class WrapPanel
    {
        public System.Collections.ArrayList Children { get; private set; }
        public object Orientation { get; set; }
        public object HorizontalAlignment { get; set; }
        public object VerticalAlignment { get; set; }
        public object Margin { get; set; }
        public object Visibility { get; set; }
        public object Tag { get; set; }

        public WrapPanel()
        {
            Children = new System.Collections.ArrayList();
        }
    }

    public class Label
    {
        public object Content { get; set; }
        public object Tag { get; set; }
        public object Cursor { get; set; }
        public object HorizontalAlignment { get; set; }
        public object Visibility { get; set; }

        public void SetResourceReference(object prop, object resource) {}
        public void Add_MouseLeftButtonUp(System.Management.Automation.ScriptBlock handler) {}
    }
}
"@
    }

    if (-not ("Windows.Controls.Border" -as [type])) {
        Add-Type @"
namespace Windows.Controls
{
    public class Border
    {
        public object Child { get; set; }
        public object Visibility { get; set; }
    }

    public class DockPanel
    {
        public System.Collections.ArrayList Children { get; private set; }
        public object Visibility { get; set; }

        public DockPanel()
        {
            Children = new System.Collections.ArrayList();
        }
    }

    public class StackPanel
    {
        public System.Collections.ArrayList Children { get; private set; }
        public object Visibility { get; set; }

        public StackPanel()
        {
            Children = new System.Collections.ArrayList();
        }
    }

    public class ItemsControl
    {
        public System.Collections.ArrayList Items { get; private set; }
        public object Visibility { get; set; }

        public ItemsControl()
        {
            Items = new System.Collections.ArrayList();
        }
    }

    public class Label
    {
        public object Content { get; set; }
        public object ToolTip { get; set; }
        public object Visibility { get; set; }
    }

    public class CheckBox
    {
        public object Content { get; set; }
        public object ToolTip { get; set; }
        public object Visibility { get; set; }
    }
}
"@
    }

    . (Join-Path $script:repoRoot "functions\private\Test-WinUtilPackageManager.ps1")
    . (Join-Path $script:repoRoot "functions\private\Find-WinUtilPackageManagerApps.ps1")
    . (Join-Path $script:repoRoot "functions\private\Find-AppsByNameOrDescription.ps1")
    . (Join-Path $script:repoRoot "functions\private\Find-TweaksByNameOrDescription.ps1")

    function global:Invoke-WPFRunspace {
        param($ScriptBlock, $ParameterList)
        $params = @{}
        if ($null -ne $ParameterList) {
            foreach ($p in $ParameterList) {
                $params[$p[0]] = $p[1]
            }
        }
        & $ScriptBlock @params
    }

    function script:New-WinUtilSearchCollection {
        return ,[System.Collections.ArrayList]::new()
    }

    function script:New-WinUtilAppSearchItem {
        param([string]$Tag)

        [pscustomobject]@{
            Tag = $Tag
            Visibility = [Windows.Visibility]::Visible
        }
    }

    function script:New-WinUtilAppCategory {
        param(
            [string]$Label,
            [object[]]$Items
        )

        $labelControl = [pscustomobject]@{
            Content = $Label
            Visibility = [Windows.Visibility]::Visible
        }
        $wrapPanel = [pscustomobject]@{
            Children = New-WinUtilSearchCollection
            Visibility = [Windows.Visibility]::Visible
        }

        foreach ($item in $Items) {
            $null = $wrapPanel.Children.Add($item)
        }

        $children = New-WinUtilSearchCollection
        $null = $children.Add($labelControl)
        $null = $children.Add($wrapPanel)

        [pscustomobject]@{
            Children = $children
            Visibility = [Windows.Visibility]::Visible
        }
    }

    function script:New-WinUtilAppSearchContext {
        param([object[]]$Categories)

        $items = New-WinUtilSearchCollection
        foreach ($category in $Categories) {
            $null = $items.Add($category)
        }

        $script:sync = [Hashtable]::Synchronized(@{
            MockedTest = $true
            ItemsControl = [pscustomobject]@{
                Items = $items
            }
            configs = @{
                applicationsHashtable = @{
                    WPFInstallBrowser = [pscustomobject]@{
                        Content = "Firefox"
                        Description = "Fast private browser"
                        Category = "Browsers"
                        winget = "Browser.App"
                        choco = "browserapp"
                    }
                    WPFInstallMedia = [pscustomobject]@{
                        Content = "VLC"
                        Description = "Media player"
                        Category = "Multimedia Tools"
                    }
                    WPFInstallLiteral = [pscustomobject]@{
                        Content = "Tool [abc]"
                        Description = "Literal wildcard sample"
                        Category = "Utilities"
                    }
                    WPFInstallEditor = [pscustomobject]@{
                        Content = "Code Editor"
                        Description = "Text editing"
                        Category = "Development"
                    }
                    WPFInstallPowerToys = [pscustomobject]@{
                        Content = "PowerToys"
                        Description = "A collection of system utilities"
                        Category = "Microsoft Tools"
                    }
                }
            }
        })
        $global:sync = $script:sync
    }

    function script:New-WinUtilFakeSearchForm {
        param(
            $TweaksPanel,
            $AppxPanel
        )

        $form = [pscustomobject]@{
            tweakspanel = $TweaksPanel
            appxpanel = $AppxPanel
        }
        $form | Add-Member -MemberType ScriptMethod -Name FindName -Value {
            param($name)

            return $this.$name
        }

        $form
    }

    function script:New-WinUtilTweakLabelItem {
        param(
            [string]$Content,
            [string]$ToolTip = ""
        )

        $item = [Windows.Controls.DockPanel]::new()
        $checkbox = [Windows.Controls.CheckBox]::new()
        $label = [Windows.Controls.Label]::new()
        $label.Content = $Content
        $label.ToolTip = $ToolTip
        $null = $item.Children.Add($checkbox)
        $null = $item.Children.Add($label)
        $item.Visibility = [Windows.Visibility]::Visible
        $item
    }

    function script:New-WinUtilTweakCheckboxItem {
        param(
            [string]$Content,
            [string]$ToolTip = ""
        )

        $item = [Windows.Controls.StackPanel]::new()
        $checkbox = [Windows.Controls.CheckBox]::new()
        $checkbox.Content = $Content
        $checkbox.ToolTip = $ToolTip
        $null = $item.Children.Add($checkbox)
        $item.Visibility = [Windows.Visibility]::Visible
        $item
    }

    function script:New-WinUtilTweakCategory {
        param(
            [string]$Label,
            [object[]]$Items
        )

        $categoryLabel = [Windows.Controls.Label]::new()
        $categoryLabel.Content = $Label
        $categoryLabel.Visibility = [Windows.Visibility]::Visible

        $itemsControl = [Windows.Controls.ItemsControl]::new()
        $null = $itemsControl.Items.Add($categoryLabel)
        foreach ($item in $Items) {
            $null = $itemsControl.Items.Add($item)
        }

        $dockPanel = [Windows.Controls.DockPanel]::new()
        $null = $dockPanel.Children.Add($itemsControl)

        $border = [Windows.Controls.Border]::new()
        $border.Child = $dockPanel
        $border.Visibility = [Windows.Visibility]::Visible

        [pscustomobject]@{
            Border = $border
            Label = $categoryLabel
            ItemsControl = $itemsControl
        }
    }

    function script:New-WinUtilTweakPanel {
        param([object[]]$Categories)

        $panel = [pscustomobject]@{
            Children = New-WinUtilSearchCollection
        }

        foreach ($category in $Categories) {
            $null = $panel.Children.Add($category.Border)
        }

        $panel
    }

    function script:New-WinUtilTweakSearchContext {
        param(
            $TweaksPanel,
            $AppxPanel = $null,
            [string]$CurrentTab = "Tweaks"
        )

        $script:sync = [Hashtable]::Synchronized(@{
            currentTab = $CurrentTab
            Form = New-WinUtilFakeSearchForm -TweaksPanel $TweaksPanel -AppxPanel $AppxPanel
        })
        $global:sync = $script:sync
    }

    function script:Remove-WinUtilSearchGlobals {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
    }
}

Describe "Find-WinUtilPackageManagerApps" {
    BeforeAll {
        function global:winget { param([Parameter(ValueFromRemainingArguments=$true)]$Arguments) }
        function global:choco { param([Parameter(ValueFromRemainingArguments=$true)]$Arguments) }
    }

    It "returns empty array when SearchString is empty" {
        $result = Find-WinUtilPackageManagerApps -SearchString ""
        @($result).Count | Should -Be 0
    }

    It "parses winget search output into objects" {
        Mock winget {
            $global:LASTEXITCODE = 0
            return "Name  Id  Version  Source`n-------------------------`nNmap  Insecure.Nmap  7.95  winget"
        }

        $result = Find-WinUtilPackageManagerApps -SearchString "nmap" -ManagerPreference "Winget"
        @($result).Count | Should -Be 1
        $result[0].Name | Should -Be "Nmap"
        $result[0].Id | Should -Be "Insecure.Nmap"
    }

    It "parses choco search output into objects" {
        Mock choco {
            $global:LASTEXITCODE = 0
            return "nmap|7.95.0"
        }

        $result = Find-WinUtilPackageManagerApps -SearchString "nmap" -ManagerPreference "Choco"
        @($result).Count | Should -Be 1
        $result[0].Name | Should -Be "nmap"
        $result[0].Id | Should -Be "nmap"
    }

    It "handles search failure gracefully" {
        Mock winget { throw "Winget error" }

        $result = Find-WinUtilPackageManagerApps -SearchString "error" -ManagerPreference "Winget"
        @($result).Count | Should -Be 0
    }
}

Describe "Find-AppsByNameOrDescription" {
    BeforeAll {
        Add-Type -AssemblyName PresentationFramework -ErrorAction SilentlyContinue
        Add-Type -AssemblyName PresentationCore -ErrorAction SilentlyContinue
        Add-Type -AssemblyName WindowsBase -ErrorAction SilentlyContinue
        function global:Initialize-InstallAppEntry { param($TargetElement, $appKey) }
    }
    AfterEach {
        Remove-WinUtilSearchGlobals
    }

    It "restores app visibility and respects collapsed category state for empty search" {
        $browserItem = New-WinUtilAppSearchItem -Tag "WPFInstallBrowser"
        $mediaItem = New-WinUtilAppSearchItem -Tag "WPFInstallMedia"
        $browserItem.Visibility = [Windows.Visibility]::Collapsed
        $mediaItem.Visibility = [Windows.Visibility]::Collapsed

        $collapsedCategory = New-WinUtilAppCategory -Label "+ Browsers" -Items @($browserItem)
        $expandedCategory = New-WinUtilAppCategory -Label "- Media" -Items @($mediaItem)
        $collapsedCategory.Children[1].Visibility = [Windows.Visibility]::Collapsed
        $expandedCategory.Children[1].Visibility = [Windows.Visibility]::Collapsed
        New-WinUtilAppSearchContext -Categories @($collapsedCategory, $expandedCategory)

        Find-AppsByNameOrDescription -SearchString ""

        $collapsedCategory.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $collapsedCategory.Children[0].Visibility | Should -Be ([Windows.Visibility]::Visible)
        $collapsedCategory.Children[1].Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $browserItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $expandedCategory.Children[1].Visibility | Should -Be ([Windows.Visibility]::Visible)
        $mediaItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
    }

    It "shows matching apps by description and hides categories without matches" {
        $browserItem = New-WinUtilAppSearchItem -Tag "WPFInstallBrowser"
        $mediaItem = New-WinUtilAppSearchItem -Tag "WPFInstallMedia"
        $editorItem = New-WinUtilAppSearchItem -Tag "WPFInstallEditor"
        $browserCategory = New-WinUtilAppCategory -Label "+ Browsers" -Items @($browserItem, $mediaItem)
        $editorCategory = New-WinUtilAppCategory -Label "- Editors" -Items @($editorItem)
        New-WinUtilAppSearchContext -Categories @($browserCategory, $editorCategory)

        Find-AppsByNameOrDescription -SearchString "private"

        $browserCategory.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $browserCategory.Children[0].Content | Should -Be "- Browsers"
        $browserCategory.Children[1].Visibility | Should -Be ([Windows.Visibility]::Visible)
        $browserItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $mediaItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $editorCategory.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $editorItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
    }

    It "matches apps by preset key" {
        $browserItem = New-WinUtilAppSearchItem -Tag "WPFInstallBrowser"
        $mediaItem = New-WinUtilAppSearchItem -Tag "WPFInstallMedia"
        $category = New-WinUtilAppCategory -Label "- Browsers" -Items @($browserItem, $mediaItem)
        New-WinUtilAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -SearchString "WPFInstallBrowser"

        $browserItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $mediaItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $category.Visibility | Should -Be ([Windows.Visibility]::Visible)
    }

    It "treats wildcard characters as literal app search text" {
        $literalItem = New-WinUtilAppSearchItem -Tag "WPFInstallLiteral"
        $mediaItem = New-WinUtilAppSearchItem -Tag "WPFInstallMedia"
        $category = New-WinUtilAppCategory -Label "- Tools" -Items @($literalItem, $mediaItem)
        New-WinUtilAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -SearchString "[abc]"

        $literalItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $mediaItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $category.Visibility | Should -Be ([Windows.Visibility]::Visible)
    }

    It "filters category chips by exact application category" {
        $utilityItem = New-WinUtilAppSearchItem -Tag "WPFInstallLiteral"
        $powerToysItem = New-WinUtilAppSearchItem -Tag "WPFInstallPowerToys"
        $category = New-WinUtilAppCategory -Label "- Tools" -Items @($utilityItem, $powerToysItem)
        New-WinUtilAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -Categories @("Utilities")

        $utilityItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $powerToysItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $category.Visibility | Should -Be ([Windows.Visibility]::Visible)
    }

    It "deduplicates package manager search results against curated applications" {
        $browserItem = New-WinUtilAppSearchItem -Tag "WPFInstallBrowser"
        $category = New-WinUtilAppCategory -Label "- Browsers" -Items @($browserItem)
        New-WinUtilAppSearchContext -Categories @($category)

        Mock Find-WinUtilPackageManagerApps {
            if ($ManagerPreference -eq "Choco") {
                return ,@([pscustomobject]@{ Name = "Browser App"; Id = "browserapp" })
            } else {
                return ,@([pscustomobject]@{ Name = "Browser App"; Id = "Browser.App" })
            }
        }

        Find-AppsByNameOrDescription -SearchString "Browser"
        $sync.preferences = [pscustomobject]@{ packagemanager = "Choco" }
        Find-AppsByNameOrDescription -SearchString "Browser2"

        # Should not create dynamic entry for Browser.App since it's already in applicationsHashtable
        Should -Invoke Find-WinUtilPackageManagerApps -Times 2
        $sync.configs.applicationsHashtable.ContainsKey("WPFInstall_dynamic_winget_Browser_App") | Should -Be $false
        $sync.configs.applicationsHashtable.ContainsKey("WPFInstall_dynamic_choco_browserapp") | Should -Be $false
    }

    It "creates dynamic entry for non-curated package manager search results" {
        $browserItem = New-WinUtilAppSearchItem -Tag "WPFInstallBrowser"
        $category = New-WinUtilAppCategory -Label "- Browsers" -Items @($browserItem)
        New-WinUtilAppSearchContext -Categories @($category)

        Mock Find-WinUtilPackageManagerApps {
            return ,@([pscustomobject]@{ Name = "Some New App"; Id = "Some.New.App" })
        }
        Mock Get-WinUtilPackageLink {
            return "https://example.com"
        }
        Mock Initialize-InstallAppEntry {}

        Find-AppsByNameOrDescription -SearchString "Some"

        Should -Invoke Find-WinUtilPackageManagerApps -Times 2
        Should -Invoke Get-WinUtilPackageLink -Times 2 -Exactly
        Should -Invoke Initialize-InstallAppEntry -Times 1 -Exactly
        $sync.configs.applicationsHashtable.ContainsKey("WPFInstall_dynamic_winget_Some_New_App") | Should -Be $true
        $sync.configs.applicationsHashtable["WPFInstall_dynamic_winget_Some_New_App"].isDynamic | Should -Be $true
    }
    It "shows apps from every selected category when several chips are active" {
        $utilityItem = New-WinUtilAppSearchItem -Tag "WPFInstallLiteral"
        $powerToysItem = New-WinUtilAppSearchItem -Tag "WPFInstallPowerToys"
        $browserItem = New-WinUtilAppSearchItem -Tag "WPFInstallBrowser"
        $category = New-WinUtilAppCategory -Label "- Tools" -Items @($utilityItem, $powerToysItem, $browserItem)
        New-WinUtilAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -Categories @("Utilities", "Microsoft Tools")

        $utilityItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $powerToysItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $browserItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
    }

    It "applies the search text and the category filter together" {
        $powerToysItem = New-WinUtilAppSearchItem -Tag "WPFInstallPowerToys"
        $literalItem = New-WinUtilAppSearchItem -Tag "WPFInstallLiteral"
        $category = New-WinUtilAppCategory -Label "- Tools" -Items @($powerToysItem, $literalItem)
        New-WinUtilAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -SearchString "PowerToys" -Categories @("Microsoft Tools")

        $powerToysItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $literalItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
    }

    It "hides a category when the search text matches nothing inside the selected categories" {
        $powerToysItem = New-WinUtilAppSearchItem -Tag "WPFInstallPowerToys"
        $category = New-WinUtilAppCategory -Label "- Tools" -Items @($powerToysItem)
        New-WinUtilAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -SearchString "Firefox" -Categories @("Microsoft Tools")

        $powerToysItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $category.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
    }

    It "expands a collapsed category that has matches for the selected filter" {
        $powerToysItem = New-WinUtilAppSearchItem -Tag "WPFInstallPowerToys"
        $category = New-WinUtilAppCategory -Label "+ Tools" -Items @($powerToysItem)
        New-WinUtilAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -Categories @("Microsoft Tools")

        $category.Children[0].Content | Should -Be "- Tools"
        $category.Children[1].Visibility | Should -Be ([Windows.Visibility]::Visible)
    }

    It "re-collapses a category it expanded once the filter is cleared" {
        $powerToysItem = New-WinUtilAppSearchItem -Tag "WPFInstallPowerToys"
        $category = New-WinUtilAppCategory -Label "+ Tools" -Items @($powerToysItem)
        New-WinUtilAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -Categories @("Microsoft Tools")
        $category.Children[0].Content | Should -Be "- Tools"

        Find-AppsByNameOrDescription -SearchString ""

        $category.Children[0].Content | Should -Be "+ Tools"
        $category.Children[1].Visibility | Should -Be ([Windows.Visibility]::Collapsed)
    }

    It "leaves a category the user had expanded alone when the filter is cleared" {
        $powerToysItem = New-WinUtilAppSearchItem -Tag "WPFInstallPowerToys"
        $category = New-WinUtilAppCategory -Label "- Tools" -Items @($powerToysItem)
        New-WinUtilAppSearchContext -Categories @($category)

        Find-AppsByNameOrDescription -Categories @("Microsoft Tools")
        Find-AppsByNameOrDescription -SearchString ""

        $category.Children[0].Content | Should -Be "- Tools"
        $category.Children[1].Visibility | Should -Be ([Windows.Visibility]::Visible)
    }
}

Describe "Find-TweaksByNameOrDescription" {
    AfterEach {
        Remove-WinUtilSearchGlobals
    }

    It "restores category labels and respects collapsed category state for empty search" {
        $collapsedItem = New-WinUtilTweakLabelItem -Content "Disable Telemetry" -ToolTip "Stop tracking"
        $expandedItem = New-WinUtilTweakCheckboxItem -Content "Show Extensions" -ToolTip "File extension display"
        $collapsedCategory = New-WinUtilTweakCategory -Label "+ Privacy" -Items @($collapsedItem)
        $expandedCategory = New-WinUtilTweakCategory -Label "- Explorer" -Items @($expandedItem)
        $expandedItem.Visibility = [Windows.Visibility]::Collapsed
        $collapsedCategory.Label.Visibility = [Windows.Visibility]::Collapsed
        $collapsedCategory.Border.Visibility = [Windows.Visibility]::Collapsed
        $expandedCategory.Border.Visibility = [Windows.Visibility]::Collapsed
        $panel = New-WinUtilTweakPanel -Categories @($collapsedCategory, $expandedCategory)
        New-WinUtilTweakSearchContext -TweaksPanel $panel

        Find-TweaksByNameOrDescription -SearchString ""

        $collapsedCategory.Border.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $collapsedCategory.Label.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $collapsedCategory.Label.Content | Should -Be "+ Privacy"
        $collapsedItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $expandedCategory.Border.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $expandedCategory.Label.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $expandedCategory.Label.Content | Should -Be "- Explorer"
        $expandedItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
    }

    It "shows tweak matches by label tooltip and checkbox content" {
        $telemetryItem = New-WinUtilTweakLabelItem -Content "Disable Telemetry" -ToolTip "Stop tracking"
        $extensionsItem = New-WinUtilTweakCheckboxItem -Content "Show Extensions" -ToolTip "File extension display"
        $nonMatchItem = New-WinUtilTweakLabelItem -Content "Enable NumLock" -ToolTip "Keyboard setting"
        $category = New-WinUtilTweakCategory -Label "+ Privacy" -Items @($telemetryItem, $extensionsItem, $nonMatchItem)
        $panel = New-WinUtilTweakPanel -Categories @($category)
        New-WinUtilTweakSearchContext -TweaksPanel $panel

        Find-TweaksByNameOrDescription -SearchString "tracking"

        $category.Border.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $category.Label.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $category.Label.Content | Should -Be "- Privacy"
        $telemetryItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $extensionsItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $nonMatchItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)

        Find-TweaksByNameOrDescription -SearchString "Show Extensions"

        $telemetryItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $extensionsItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $nonMatchItem.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
    }

    It "hides tweak category panels when no items match" {
        $item = New-WinUtilTweakLabelItem -Content "Disable Telemetry" -ToolTip "Stop tracking"
        $category = New-WinUtilTweakCategory -Label "- Privacy" -Items @($item)
        $panel = New-WinUtilTweakPanel -Categories @($category)
        New-WinUtilTweakSearchContext -TweaksPanel $panel

        Find-TweaksByNameOrDescription -SearchString "not-present"

        $category.Border.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $category.Label.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
        $item.Visibility | Should -Be ([Windows.Visibility]::Collapsed)
    }

    It "searches the AppX panel when AppX is the current tab" {
        $tweakItem = New-WinUtilTweakLabelItem -Content "Disable Telemetry" -ToolTip "Stop tracking"
        $appxItem = New-WinUtilTweakCheckboxItem -Content "Xbox Overlay" -ToolTip "Gaming overlay package"
        $tweakCategory = New-WinUtilTweakCategory -Label "- Privacy" -Items @($tweakItem)
        $appxCategory = New-WinUtilTweakCategory -Label "+ AppX" -Items @($appxItem)
        $tweakPanel = New-WinUtilTweakPanel -Categories @($tweakCategory)
        $appxPanel = New-WinUtilTweakPanel -Categories @($appxCategory)
        New-WinUtilTweakSearchContext -TweaksPanel $tweakPanel -AppxPanel $appxPanel -CurrentTab "AppX"

        Find-TweaksByNameOrDescription -SearchString "overlay"

        $appxCategory.Border.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $appxCategory.Label.Content | Should -Be "- AppX"
        $appxItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $tweakCategory.Border.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $tweakItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
    }
}
