function Install-WinUtilChoco {

    if (Get-Command -Name choco) {
        return
    }

    Write-Host "Chocolatey is not installed. Installing..."
    Invoke-RestMethod -Uri https://community.chocolatey.org/install.ps1 | Invoke-Expression
}
