function Get-WinUtilVariables {

    <#
    
        .DESCRIPTION
        palceholder
    
    #>
    param (
        [Parameter()]
        [ValidateSet("CheckBox", "Button")]
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
