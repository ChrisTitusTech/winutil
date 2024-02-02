function Invoke-WPFPresets {
    <#

    .SYNOPSIS
        Sets the options in the tweaks panel to the given preset

    .PARAMETER preset
        The preset to set the options to

    .PARAMETER imported
        If the preset is imported from a file, defaults to false

    .PARAMETER checkbox
        The checkbox to set the options to, defaults to 'WPFTweaks'

    #>

    param(
        $preset,
        [bool]$imported = $false,
        $checkbox = "WPFTweaks"
    )

    if($imported -eq $true){
        $CheckBoxesToCheck = $preset
    }
    Else{
        $CheckBoxesToCheck = $sync.configs.preset.$preset
    }

    if($checkbox -eq "WPFTweaks"){
        $filter = Get-WinUtilVariables -Type Checkbox | Where-Object {$psitem -like "*tweaks*"}
        $sync.GetEnumerator() | Where-Object {$psitem.Key -in $filter} | ForEach-Object {
            if ($CheckBoxesToCheck -contains $PSItem.name){
                $sync.$($PSItem.name).ischecked = $true
            }
            else{$sync.$($PSItem.name).ischecked = $false}
        }
    }
    if($checkbox -eq "WPFInstall"){

        $filter = Get-WinUtilVariables -Type Checkbox | Where-Object {$psitem -like "WPFInstall*"}
        $sync.GetEnumerator() | Where-Object {$psitem.Key -in $filter} | ForEach-Object {
            if($($sync.configs.applications.$($psitem.name).winget) -in $CheckBoxesToCheck){
                $sync.$($PSItem.name).ischecked = $true
            }
            else{$sync.$($PSItem.name).ischecked = $false}
        }
    }
}