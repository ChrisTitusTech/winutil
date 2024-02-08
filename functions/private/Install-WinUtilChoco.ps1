function Install-WinUtilChoco {

    <#

    .SYNOPSIS
        Installs Chocolatey if it is not already installed

    #>

    try {
        Write-Host "Checking if Chocolatey is Installed..."

        if((Get-Command -Name choco -ErrorAction Ignore)) {
            Write-Host "Chocolatey Already Installed"
            return
        }

        Write-Host "Seems Chocolatey is not installed, installing now"
        Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) -ErrorAction Stop
        powershell choco feature enable -n allowGlobalConfirmation

    }
    Catch {
        Write-Host "==========================================="
        Write-Host "--     Chocolatey failed to install     ---"
        Write-Host "==========================================="
    }

}
