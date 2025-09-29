function Test-WinUtilInternetConnection {
    <#
    .SYNOPSIS
        Tests if the computer has internet connectivity
    .OUTPUTS
        Boolean - True if connected, False if offline
    #>
    try {
        # Test multiple reliable endpoints
        $testSites = @(
            "8.8.8.8",           # Google DNS
            "1.1.1.1",           # Cloudflare DNS
            "208.67.222.222"     # OpenDNS
        )

        foreach ($site in $testSites) {
            if (Test-Connection -ComputerName $site -Count 1 -Quiet -ErrorAction SilentlyContinue) {
                return $true
            }
        }
        return $false
    }
    catch {
        return $false
    }
}
