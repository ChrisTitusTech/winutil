function Install-WinUtilWinget {
    <#

    .SYNOPSIS
        Installs WinGet if not already installed.

    .DESCRIPTION
        installs winGet if needed
    #>
    if ((Test-WinUtilPackageManager -winget) -eq "installed") {
        return
    }

    Write-Host "WinGet is not installed. Installing now..." -ForegroundColor Red
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

    Install-PackageProvider -Name NuGet -Force
    Install-Module Microsoft.WinGet.Client -Force
    Import-Module Microsoft.WinGet.Client
    Repair-WinGetPackageManager
}
