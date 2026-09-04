function Get-WinUtilFaviconUrl {
    <#
        .SYNOPSIS
            Builds the favicon service URL for an application link

        .PARAMETER Link
            The application website whose favicon should be requested.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Link
    )

    if ([string]::IsNullOrWhiteSpace($Link)) {
        return $null
    }

    return "https://www.google.com/s2/favicons?sz=64&domain_url=$([uri]::EscapeDataString($Link))"
}
