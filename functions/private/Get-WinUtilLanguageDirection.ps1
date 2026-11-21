function Get-WinUtilLanguageDirection {
    <#
        .SYNOPSIS
            Returns the WPF FlowDirection for a language code.

        .DESCRIPTION
            Reads the direction from config/languages.json (embedded as $sync.configs.languages),
            so adding a language only requires a locale file and an entry in that config. Falls
            back to LeftToRight when the language or its direction is unknown.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Language
    )

    $languages = $null
    if ($null -ne $sync -and $sync.ContainsKey("configs")) {
        $configs = $sync.configs
        if ($configs -is [System.Collections.IDictionary]) { $languages = $configs["languages"] } else { $languages = $configs.languages }
    }

    if ($null -ne $languages) {
        $entry = $null
        if ($languages -is [System.Collections.IDictionary]) { $entry = $languages[$Language] } else { $entry = $languages.PSObject.Properties[$Language].Value }
        if ($null -ne $entry) {
            $direction = if ($entry -is [System.Collections.IDictionary]) { $entry["flowDirection"] } else { $entry.flowDirection }
            if ($direction -eq "RightToLeft" -or $direction -eq "LeftToRight") { return [string]$direction }
        }
    }

    return "LeftToRight"
}
