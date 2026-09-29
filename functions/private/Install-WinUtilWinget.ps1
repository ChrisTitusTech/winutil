function Install-WinUtilWinget {
    <#

    .SYNOPSIS
        Installs WinGet if not already installed.

    .DESCRIPTION
        installs winGet if needed
    #>
    param(
        [switch]$Force
    )

    # The repair action needs Repair-WinGetPackageManager to run even when winget is detected,
    # which is the case a broken installation presents
    if (-not $Force -and (Test-WinUtilPackageManager -winget) -eq "installed") {
        return
    }

    if ($Force) {
        Write-Host "Repairing the WinGet installation..." -ForegroundColor Yellow
    } else {
        Write-Host "WinGet is not installed. Installing now..." -ForegroundColor Red
    }

    Install-PackageProvider -Name NuGet -Force
    Install-Module -Name Microsoft.WinGet.Client -Force
    Repair-WinGetPackageManager -AllUsers
}
