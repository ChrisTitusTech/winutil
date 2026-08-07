function Invoke-WPFTab {

    <#

    .SYNOPSIS
        Sets the selected tab to the tab that was clicked

    .PARAMETER ClickedTab
        The name of the tab that was clicked

    #>

    Param (
        [Parameter(Mandatory,position=0)]
        [string]$ClickedTab
    )

    $tabNumber = [int]($ClickedTab -replace "WPFTab","" -replace "BT","") - 1

    Measure-WinUtilStep -Scope "Tab" -Name "$ClickedTab select" -ScriptBlock {
        $filter = Get-WinUtilVariables -Type ToggleButton | Where-Object {$psitem -like "WPFTab?BT"}
        $sync.WPFTabNav.Items[$tabNumber].IsSelected = $true
        ($sync.GetEnumerator()).where{$psitem.Key -in $filter} | ForEach-Object {
            if ($ClickedTab -ne $PSItem.name) {
                $sync[$PSItem.Name].IsChecked = $false
            } else {
                $sync["$ClickedTab"].IsChecked = $true
            }
        }
        $sync.currentTab = $sync.WPFTabNav.Items[$tabNumber].Header
    }

    Measure-WinUtilStep -Scope "Tab" -Name "$ClickedTab content" -ScriptBlock {
        Initialize-WinUtilTabContent -TabName $sync.currentTab
    }

    Measure-WinUtilStep -Scope "Tab" -Name "$ClickedTab filter reset" -ScriptBlock {
        if ($sync.currentTab -eq "Install") {
            Find-AppsByNameOrDescription -SearchString ""
        } elseif ($sync.currentTab -eq "Tweaks" -or $sync.currentTab -eq "AppX") {
            Find-TweaksByNameOrDescription -SearchString ""
        }
    }

    Measure-WinUtilStep -Scope "Tab" -Name "$ClickedTab search bar" -ScriptBlock {
        # Show search bar in Install, Tweaks, and AppX tabs
        $searchIcon = ($sync.Form.FindName("SearchBar").Parent.Children | Where-Object { $_ -is [System.Windows.Controls.TextBlock] -and $_.Text -eq [char]0xE721 })[0]
        if ($tabNumber -eq 0 -or $tabNumber -eq 1 -or $tabNumber -eq 5) {
            $sync.SearchBar.Visibility = "Visible"
            if ($searchIcon) { $searchIcon.Visibility = "Visible" }
        } else {
            $sync.SearchBar.Visibility = "Collapsed"
            if ($searchIcon) { $searchIcon.Visibility = "Collapsed" }
            $sync.SearchBarClearButton.Visibility = "Collapsed"
        }
    }
}
