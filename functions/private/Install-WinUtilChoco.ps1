function Install-WinUtilChoco {
    if (-not (Get-Command -Name choco)) {
      Write-Host "Chocolatey is not installed. Installing now..."
      $installScript = Invoke-WebRequest -Uri https://community.chocolatey.org/install.ps1 -UseBasicParsing
      Invoke-Command -ScriptBlock ([scriptblock]::Create($installScript.Content))
    }
}
