function Invoke-WinUtilTweaks {
    <#
    
        .DESCRIPTION
        This function converts all the values from the tweaks.json and routes them to the appropriate function
    
    #>

    param(
        $CheckBox,
        $undo = $false
    )
    if($undo){
        $Values = @{
            Registry = "OriginalValue"
            ScheduledTask = "OriginalState"
            Service = "OriginalType"
        }
    }    
    Else{
        $Values = @{
            Registry = "Value"
            ScheduledTask = "State"
            Service = "StartupType"
        }
    }

    if($sync.configs.tweaks.$CheckBox.registry){
        $sync.configs.tweaks.$CheckBox.registry | ForEach-Object {
            Set-WinUtilRegistry -Name $psitem.Name -Path $psitem.Path -Type $psitem.Type -Value $psitem.$($values.registry)
        }
    }
    if($sync.configs.tweaks.$CheckBox.ScheduledTask){
        $sync.configs.tweaks.$CheckBox.ScheduledTask | ForEach-Object {
            Set-WinUtilScheduledTask -Name $psitem.Name -State $psitem.$($values.ScheduledTask)
        }
    }
    if($sync.configs.tweaks.$CheckBox.service){
        $sync.configs.tweaks.$CheckBox.service | ForEach-Object {
            Set-WinUtilService -Name $psitem.Name -StartupType $psitem.$($values.Service)
        }
    }

    if(!$undo){
        if($sync.configs.tweaks.$CheckBox.appx){
            $sync.configs.tweaks.$CheckBox.appx | ForEach-Object {
                Remove-WinUtilAPPX -Name $psitem
            }
        }
        if($sync.configs.tweaks.$CheckBox.InvokeScript){
            $sync.configs.tweaks.$CheckBox.InvokeScript | ForEach-Object {
                $Scriptblock = [scriptblock]::Create($psitem)
                Invoke-WinUtilScript -ScriptBlock $scriptblock -Name $CheckBox
            }
        }
    }
}
