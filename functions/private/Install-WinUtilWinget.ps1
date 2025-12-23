function Install-WinUtilWinget {
    <#

    .SYNOPSIS
        Installs Winget if not already installed.

    .DESCRIPTION
        installs winget if needed
    #>
    if ((Test-WinUtilPackageManager -winget) -eq "installed") {
        return
    }

    Write-Host "Winget is not Installed. Installing." -ForegroundColor Red
        
    Install-PackageProvider -Name NuGet -Force
    Install-Module "Microsoft.WinGet.Client" -Force
    Repair-WinGetPackageManager
}
