function Install-WinUtilWinget {

    if (Get-Command -Name winget) {
        return
    }

    Write-Host "WinGet is not installed. Installing..." -ForegroundColor Red

    Install-PackageProvider -Name NuGet -Force
    Install-Module -Name Microsoft.WinGet.Client -Force
    Repair-WinGetPackageManager -AllUsers
}
