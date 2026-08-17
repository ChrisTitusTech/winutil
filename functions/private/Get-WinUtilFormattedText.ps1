function Get-WinUtilFormattedText {
    <#
    .SYNOPSIS
        Returns the localized text for a format-template string with placeholder
        arguments ({0}, {1}, ...), e.g. "Installing {0} ({1}/{2})". The English
        template itself is the i18n.json key; translations must keep the same
        placeholders.

        Falls back to the English template when no translation exists or the
        translated template cannot be formatted (a missing placeholder or a
        stray brace must never break the caller).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Template,

        [Parameter(Mandatory = $true)]
        [object[]]$FormatArgs
    )

    $resolved = Get-WinUtilText $Template
    try {
        return [string]::Format($null, $resolved, $FormatArgs)
    } catch {
        return [string]::Format($null, $Template, $FormatArgs)
    }
}
