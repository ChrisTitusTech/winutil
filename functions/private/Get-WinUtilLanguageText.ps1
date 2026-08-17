function Get-WinUtilLanguageText {
    <#
    .SYNOPSIS
        Resolves a string against the current language state. With an active
        TextTable it translates forward (English key -> translated text). With
        no TextTable but a ReverseTextTable (switching back to English) it
        translates backward (translated text -> English key). Falls back to the
        original string when nothing matches.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    if ($null -ne $sync.TextTable -and $sync.TextTable.Count -gt 0) {
        if ($sync.TextTable.ContainsKey($Text)) {
            return $sync.TextTable[$Text]
        }
        return $Text
    }

    if ($null -ne $sync.ReverseTextTable -and $sync.ReverseTextTable.ContainsKey($Text)) {
        return $sync.ReverseTextTable[$Text]
    }

    return $Text
}
