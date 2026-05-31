function Install-WinUtilChoco {

    if (-not (Get-Command choco)) {
        return
    }

    Write-Host "Chocolatey is not installed. Installing now..."
    Invoke-WebRequest -Uri https://community.chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
}
