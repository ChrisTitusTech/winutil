function Install-WinUtilChoco {

    <#
    
        .DESCRIPTION
        Installs Chocolatey if it is not installed
    
    #>

    try{
        Write-Host "Checking if Chocolatey is Installed..."

        if((Test-WinUtilPackageManager -choco)){
            Write-Host "Chocolatey Already Installed"
            return
        }
    
        Write-Host "Seems Chocolatey is not installed, installing now?"
        # Let user decide if they want to install Chocolatey
        $confirmation = Read-Host "Are you Sure You Want To Proceed:(y/n)"
        if ($confirmation -eq 'y') {
            Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) -ErrorAction Stop
            powershell choco feature enable -n allowGlobalConfirmation
        }
    }
    Catch{
        throw [ChocoFailedInstall]::new('Failed to install')
    }

}
