function Get-WinUtilConfigToolTip {
    <#
        .SYNOPSIS
            Builds a tooltip that includes an entry's configuration key.
        .PARAMETER Description
            The user-facing description of the configuration entry.
        .PARAMETER ConfigKey
            The key used to reference the entry in an exported configuration.
    #>
    param(
        [AllowEmptyString()]
        [string]$Description,

        [Parameter(Mandatory)]
        [string]$ConfigKey
    )

    $configKeyText = "Configuration key: $ConfigKey"
    if ([string]::IsNullOrWhiteSpace($Description)) {
        return $configKeyText
    }

    return "$Description`n`n$configKeyText"
}
