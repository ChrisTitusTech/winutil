function Get-WinUtilFaviconUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Link
    )

    if ([string]::IsNullOrWhiteSpace($Link)) {
        return $null
    }

    return "https://www.google.com/s2/favicons?sz=64&domain_url=$([uri]::EscapeDataString($Link))"
}
