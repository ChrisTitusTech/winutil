function Install-WinUtilWinget {
    <#

    .SYNOPSIS
        Installs Winget if not already installed.

    .DESCRIPTION
        This function will install winget if not already installed, and update winget if needed
    #>
    $isWingetInstalled = Test-WinUtilPackageManager -winget
    
    if ($isWingetInstalled -eq "installed") {
        Write-Host "`nWinget is already installed.`r" -ForegroundColor Green
        return
    } elseif ($isWingetInstalled -eq "outdated") {
        Write-Host "`nWinget is Outdated. Updating...`r" -ForegroundColor Yellow
        winget upgrade Microsoft.AppInstaller --source winget
    } else {
        Write-Host "`nWinget is not Installed. Installing...`r" -ForegroundColor Red
        
        Install-PackageProvider -Name NuGet -Force
        Install-Module "Microsoft.WinGet.Client" -Force
        Repair-WinGetPackageManager

        Write-Host "WinGet installed successful!" -ForegroundColor Green
    }
}
