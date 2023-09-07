function Install-WinUtilChoco {
    try{
        Write-Host "Checking if Chocolatey is Installed..."
        if((Test-WinUtilPackageManager -choco)){
            Write-Host "Chocolatey Already Installed"
            return
        }
        Write-Host "Seems Chocolatey is not installed, installing now"
        Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) -ErrorAction Stop
        powershell choco feature enable -n allowGlobalConfirmation
    }
    Catch{
        throw [ChocoFailedInstall]::new('Failed to install Chocolatey')
    }
}