function Invoke-WinUtilTweaks {
    <#
    
    .DESCRIPTION
    This function converts all the values from the tweaks.json and routes them to the appropriate function
    
    #>
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$TweakName,
        [Parameter(Mandatory=$false)]
        [switch]$undo
    )
    if($undo){
        $Values = @{
            Registry = "OriginalValue"
            ScheduledTask = "OriginalState"
            Service = "OriginalType"
            ScriptType = "UndoScript"
        }

    }    
    Else{
        $Values = @{
            Registry = "Value"
            ScheduledTask = "State"
            Service = "StartupType"
            ScriptType = "InvokeScript"
        }
    }
    # TODO: add support for confrim and whatif
    if($sync.configs.tweaks.$TweakName.ScheduledTask){
        $sync.configs.tweaks.$TweakName.ScheduledTask | ForEach-Object {
            Set-WinUtilScheduledTask -Name $psitem.Name -State $psitem.$($values.ScheduledTask)
        }
    }
    if($sync.configs.tweaks.$TweakName.service){
        $sync.configs.tweaks.$TweakName.service | ForEach-Object {
            Set-WinUtilService -Name $psitem.Name -StartupType $psitem.$($values.Service)
        }
    }
    if($sync.configs.tweaks.$TweakName.registry){
        $sync.configs.tweaks.$TweakName.registry | ForEach-Object {
            Set-WinUtilRegistry -Name $psitem.Name -Path $psitem.Path -Type $psitem.Type -Value $psitem.$($values.registry)
        }
    }
    if($sync.configs.tweaks.$TweakName.$($values.ScriptType)){
        $sync.configs.tweaks.$TweakName.$($values.ScriptType) | ForEach-Object {
            $Scriptblock = [scriptblock]::Create($psitem)
            Invoke-WinUtilScript -ScriptBlock $scriptblock -Name $TweakName
        }
    }

    if(!$undo){
        if($sync.configs.tweaks.$TweakName.appx){
            $sync.configs.tweaks.$TweakName.appx | ForEach-Object {
                Remove-WinUtilAPPX -Name $psitem
            }
        }

    }
}