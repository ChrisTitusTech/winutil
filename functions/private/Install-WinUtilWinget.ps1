function Install-WinUtilWinget {
    <#

    .SYNOPSIS
        Installs Winget if not already installed.

    .DESCRIPTION
        This function will install winget if not already installed, and update winget if needed
    #>
    $isWingetInstalled = Test-WinUtilPackageManager -winget
    
    if (-not ($isWingetInstalled -eq "installed")) {
        Write-Host "`nWinget is not Installed. Installing...`r" -ForegroundColor Red
        
        Install-PackageProvider -Name NuGet -Force
        Install-Module "Microsoft.WinGet.Client" -Force
        Repair-WinGetPackageManager

        Write-Host "WinGet installed successful!" -ForegroundColor Green
    }
}
