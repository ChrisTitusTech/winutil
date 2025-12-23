function Install-WinUtilChoco {

    <#

    .SYNOPSIS
        Installs Chocolatey if it is not already installed

    #>

    try {
        Write-Host "Checking if Chocolatey is Installed..."

        if ((Test-WinUtilPackageManager -choco) -eq "installed") {
            return
        }
        
        Write-Host "Chocolatey is not installed, installing now."
        Invoke-WebRequest https://community.chocolatey.org/install.ps1 | Invoke-Expression

    } catch {
        Write-Host "===========================================" -Foregroundcolor Red
        Write-Host "--     Chocolatey failed to install     ---" -Foregroundcolor Red
        Write-Host "===========================================" -Foregroundcolor Red
    }

}
