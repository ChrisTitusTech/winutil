function Install-WinUtilChoco {

    <#

    .SYNOPSIS
        Installs Chocolatey if it is not already installed

    #>
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        return
    }

    Write-Host "Chocolatey is not installed. Installing now..."
    Invoke-WebRequest -Uri https://community.chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
}
