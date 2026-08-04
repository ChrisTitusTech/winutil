$root = Split-Path $PSScriptRoot -Parent

Push-Location $root

.\Compile.ps1
.\winutil.ps1

Pop-Location