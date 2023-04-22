function Invoke-WPFTab {

    <#
    
        .DESCRIPTION
        Sole purpose of this fuction reduce duplicated code for switching between tabs. 
    
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
