function Microwin-GetLocalizedUsers
{
    <#
        .SYNOPSIS
            Gets a localized user group representation for ICACLS commands (Port from DISMTools PE Helper)
        .PARAMETER admins
            Determines whether to get a localized user group representation for the Administrators user group
        .OUTPUTS
            A string containing the localized user group
        .EXAMPLE
            Microwin-GetLocalizedUsers -admins $true
    #>
    param (
        [Parameter(Mandatory = $true, Position = 0)] [bool]$admins
    )
    if ($admins) {
        return (Get-LocalGroup | Where-Object { $_.SID.Value -like "S-1-5-32-544" }).Name
    } else {
        return (Get-LocalGroup | Where-Object { $_.SID.Value -like "S-1-5-32-545" }).Name
    }
}
