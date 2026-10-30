function Get-WinUtilEntryToolTip {
    <#
        .SYNOPSIS
            Builds the tooltip string for an app/tweak/feature entry: its description plus its preset JSON key

        .PARAMETER Description
            The entry's description from the config JSON. May be null or empty.

        .PARAMETER Key
            The entry's JSON key as used in preset files (e.g. WPFInstallbrave, WPFTweaksTele).
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $false)]
        [string]$License
    )

    $footer = "Preset key: $Key"
    if (-not [string]::IsNullOrWhiteSpace($License)) {
        $footer = "License: $License`n$footer"
    }

    if ([string]::IsNullOrWhiteSpace($Description)) {
        return $footer
    }

    return "$Description`n`n$footer"
}
