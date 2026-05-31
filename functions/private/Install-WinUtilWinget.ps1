function Install-WinUtilWinget {

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        return
    }

    Write-Host "WinGet is not installed. Installing now..." -ForegroundColor Red

    Install-PackageProvider -Name NuGet -Force
    Install-Module -Name Microsoft.WinGet.Client -Force
    Repair-WinGetPackageManager -AllUsers
}
