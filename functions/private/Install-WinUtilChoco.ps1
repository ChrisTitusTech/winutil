function Install-WinUtilChoco {

    <#

    .SYNOPSIS
        Installs Chocolatey if it is not already installed

    #>
    if ((Test-WinUtilPackageManager -choco) -eq "installed") {
        return
    }

    Write-Host "Chocolatey is not installed. Installing now..."
    $installScript = Invoke-WebRequest -Uri https://community.chocolatey.org/install.ps1 -UseBasicParsing
    Invoke-Command -ScriptBlock ([scriptblock]::Create($installScript.Content))
}
