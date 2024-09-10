function Install-WinUtilChoco {

    <#

    .SYNOPSIS
        Installs Chocolatey if it is not already installed

    #>

    try {
        Write-Host "Checking if Chocolatey is Installed..."

        if((Test-WinUtilPackageManager -choco) -eq "installed") {
            return
        }

        Write-Host "Seems Chocolatey is not installed, installing now."
        Start-Process -FilePath "powershell" -ArgumentList "Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) -ErrorAction Stop" -Wait -NoNewWindow
        Start-Process -FilePath "powershell" -ArgumentList "choco feature enable -n allowGlobalConfirmation" -Wait -NoNewWindow

    } catch {
        Write-Host "===========================================" -Foregroundcolor Red
        Write-Host "--     Chocolatey failed to install     ---" -Foregroundcolor Red
        Write-Host "===========================================" -Foregroundcolor Red
    }

}
