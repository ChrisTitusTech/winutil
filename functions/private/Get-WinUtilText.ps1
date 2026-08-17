function Get-WinUtilText {
    <#
    .SYNOPSIS
        Returns the localized text for a string in the current language.
        Falls back to the original string when no translation exists or no language is active.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$String
    )

    if ($null -eq $sync.TextTable -or $sync.TextTable.Count -eq 0) {
        return $String
    }

    if ($sync.TextTable.ContainsKey($String)) {
        return $sync.TextTable[$String]
    }

    return $String
}
