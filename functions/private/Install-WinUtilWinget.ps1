function Install-WinUtilWinget {
    <#

    .SYNOPSIS
        Installs WinGet if not already installed.

    .DESCRIPTION
        installs winGet if needed
    #>
    if ((Test-WinUtilPackageManager -winget) -eq "installed") {
        # The client module is what reports install progress, so make it available while the
        # user is already waiting rather than on the first package
        Install-WinUtilWinGetClient | Out-Null
        return
    }

    Write-Host "WinGet is not installed. Installing now..." -ForegroundColor Red

    Install-PackageProvider -Name NuGet -Force
    Install-Module -Name Microsoft.WinGet.Client -Force
    Repair-WinGetPackageManager -AllUsers
}
