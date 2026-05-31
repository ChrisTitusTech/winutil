function Install-WinUtilChoco {

    if (Get-Command -Name choco) {
        return
    }

    Invoke-WebRequest -Uri https://community.chocolatey.org/api/v2/package/chocolatey -OutFile "chocolatey.zip"
    Expand-Archive -Path "chocolatey.zip"

    New-Item -Path $Env:ProgramData\chocolatey\lib\chocolatey -ItemType Directory  -Force

    Move-Item -Path "chocolatey\tools\chocolateyInstall\*" -Destination $Env:ProgramData\chocolatey
    Move-Item -Path "chocolatey.zip" -Destination $Env:ProgramData\chocolatey\lib\chocolatey\chocolatey.nupkg

    $Path = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    [Environment]::SetEnvironmentVariable("PATH", $Path + ";$Env:ProgramData\chocolatey", "Machine")
    $Env:Path = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")

    Remove-Item -Path "chocolatey" -Recurse
}
