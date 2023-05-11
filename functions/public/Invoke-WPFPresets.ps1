function Invoke-WPFPresets {
    <#

        .DESCRIPTION
        Meant to make settings presets easier in the tweaks tab. Will pull the data from config/preset.json

    #>

    param(
        $preset,
        [bool]$imported = $false,
        $checkbox = "WPFTeaks"
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