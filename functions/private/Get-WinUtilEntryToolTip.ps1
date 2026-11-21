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
        [string]$Key
    )

    $label = "Preset key:"
    $locales = $sync.configs.locales
    $language = if ($sync.preferences) { $sync.preferences.language } else { $null }
    if ($locales -and $language) {
        $locale = if ($locales -is [System.Collections.IDictionary]) { $locales[$language] } else { $locales.$language }
        if ($null -ne $locale) {
            $p = $locale.PSObject.Properties["s_preset_key"]
            if ($null -ne $p) { $label = [string]$p.Value }
        }
    }

    if ([string]::IsNullOrWhiteSpace($Description)) {
        return "$label $Key"
    }

    return "$Description`n`n$label $Key"
}
