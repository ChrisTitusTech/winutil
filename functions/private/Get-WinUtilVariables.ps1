function Get-WinUtilVariables {

    <#
    .SYNOPSIS
        Gets every form object of the provided type

    .OUTPUTS
        List containing every object that matches the provided type
    #>
    param (
        [Parameter()]
        [string[]]$Type
    )

    $keys = $sync.keys | Where-Object { $_ -like "WPF*" }

    if ($Type) {
        $output = $keys | ForEach-Object {
            Try {
                $objType = $sync["$psitem"].GetType().Name
                if ($Type -contains $objType) {
                    Write-Output $psitem
                }
            }
            Catch {
                <#I am here so errors don't get outputted for a couple variables that don't have the .GetType() attribute#>
            }
        }
        return $output
    }
    return $keys
}
