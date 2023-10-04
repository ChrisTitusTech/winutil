function Invoke-WPFTab {

    <#

    .SYNOPSIS
        Sets the selected tab to the tab that was clicked

    .PARAMETER ClickedTab
        The name of the tab that was clicked

    #>

    Param ($ClickedTab)
    $Tabs = Get-WinUtilVariables | Where-Object {$psitem -like "WPFTab?BT"}
    $TabNav = Get-WinUtilVariables | Where-Object {$psitem -like "WPFTabNav"}
    $x = [int]($ClickedTab -replace "WPFTab","" -replace "BT","") - 1

    0..($Tabs.Count -1 ) | ForEach-Object {

        if ($x -eq $psitem){
            $sync.$TabNav.Items[$psitem].IsSelected = $true
        }
        else{
            $sync.$TabNav.Items[$psitem].IsSelected = $false
        }
    }
}
