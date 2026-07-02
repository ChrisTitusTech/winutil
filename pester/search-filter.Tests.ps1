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

    . (Join-Path $script:repoRoot "functions\private\Find-AppsByNameOrDescription.ps1")
    . (Join-Path $script:repoRoot "functions\private\Find-TweaksByNameOrDescription.ps1")

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
            ItemsControl = [pscustomobject]@{
                Items = $items
            }
            configs = @{
                applicationsHashtable = @{
                    WPFInstallBrowser = [pscustomobject]@{
                        Content = "Firefox"
                        Description = "Fast private browser"
                    }
                    WPFInstallMedia = [pscustomobject]@{
                        Content = "VLC"
                        Description = "Media player"
                    }
                    WPFInstallLiteral = [pscustomobject]@{
                        Content = "Tool [abc]"
                        Description = "Literal wildcard sample"
                    }
                    WPFInstallEditor = [pscustomobject]@{
                        Content = "Code Editor"
                        Description = "Text editing"
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
        Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
    }
}

Describe "Find-AppsByNameOrDescription" {
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
}

Describe "Find-TweaksByNameOrDescription" {
    AfterEach {
        Remove-WinUtilSearchGlobals
    }

    It "restores category labels and tweak item visibility for empty search" {
        $labelItem = New-WinUtilTweakLabelItem -Content "Disable Telemetry" -ToolTip "Stop tracking"
        $stackItem = New-WinUtilTweakCheckboxItem -Content "Show Extensions" -ToolTip "File extension display"
        $category = New-WinUtilTweakCategory -Label "+ Privacy" -Items @($labelItem, $stackItem)
        $labelItem.Visibility = [Windows.Visibility]::Collapsed
        $stackItem.Visibility = [Windows.Visibility]::Collapsed
        $category.Label.Visibility = [Windows.Visibility]::Collapsed
        $category.Border.Visibility = [Windows.Visibility]::Collapsed
        $panel = New-WinUtilTweakPanel -Categories @($category)
        New-WinUtilTweakSearchContext -TweaksPanel $panel

        Find-TweaksByNameOrDescription -SearchString ""

        $category.Border.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $category.Label.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $labelItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
        $stackItem.Visibility | Should -Be ([Windows.Visibility]::Visible)
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
