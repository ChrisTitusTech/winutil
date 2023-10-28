function Get-WinUtilVariables {

    <#

    .SYNOPSIS
        Gets every form object of the provided type

    .OUTPUTS
        List containing every object that matches the provided type

    #>
    param (
        [Parameter()]
        [ValidateSet("CheckBox", "Button", "ToggleButton")]
        [string]$Type
    )

    $keys = $sync.keys | Where-Object {$psitem -like "WPF*"}

    if($type){
        $output = $keys | ForEach-Object {
            Try{
                if ($sync["$psitem"].GetType() -like "*$type*"){
                    Write-Output $psitem
                }
            }
            Catch{<#I am here so errors don't get outputted for a couple variables that don't have the .GetType() attribute#>}
        }
        return $output
    }
    return $keys
}
