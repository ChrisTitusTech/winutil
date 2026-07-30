function Get-WinUtilFaviconUrl {
    <#
        .SYNOPSIS
            Builds the Google favicon service URL for an application link.
        .PARAMETER Link
            The application website URL whose favicon should be requested.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Link
    )

    if ([string]::IsNullOrWhiteSpace($Link)) {
        return $null
    }

    $faviconSize = 64
    return "https://www.google.com/s2/favicons?sz=$faviconSize&domain_url=$([uri]::EscapeDataString($Link))"
}
