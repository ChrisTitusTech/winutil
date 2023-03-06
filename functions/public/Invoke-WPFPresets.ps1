function Invoke-WPFPresets {
    <#

        .DESCRIPTION
        Meant to make settings presets easier in the tweaks tab. Will pull the data from config/preset.json

    #>

    param(
        $preset,
        [bool]$imported = $false
    )
    if($imported -eq $true){
        $CheckBoxesToCheck = $preset
    }
    Else{
        $CheckBoxesToCheck = $sync.configs.preset.$preset
    }

    #Uncheck all
    get-variable | Where-Object {$_.name -like "*tweaks*"} | ForEach-Object {
        if ($psitem.value.gettype().name -eq "CheckBox"){
            $CheckBox = Get-Variable $psitem.Name
            if ($CheckBoxesToCheck -contains $CheckBox.name){
                $checkbox.value.ischecked = $true
            }
            else{$checkbox.value.ischecked = $false}
        }
    }

}