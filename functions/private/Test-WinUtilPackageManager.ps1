function Test-WinUtilPackageManager {
    <#

    .SYNOPSIS
        Checks if Winget and/or Choco are installed

    .PARAMETER winget
        Check if Winget is installed

    .PARAMETER choco
        Check if Chocolatey is installed

    #>

    Param(
        [System.Management.Automation.SwitchParameter]$winget,
        [System.Management.Automation.SwitchParameter]$choco
    )

    $status = "not-installed"

    if ($winget) {
        # Check if Winget is available while getting it's Version if it's available
        $wingetExists = $true
        try {
            $wingetVersionFull = winget --version
        } catch [System.Management.Automation.CommandNotFoundException], [System.Management.Automation.ApplicationFailedException] {
            Write-Warning "Winget was not found due to un-availablity reasons"
            $wingetExists = $false
        } catch {
            Write-Warning "Winget was not found due to un-known reasons, The Stack Trace is:`n$($psitem.Exception.StackTrace)"
            $wingetExists = $false
    }

        # If Winget is available, Parse it's Version and give proper information to Terminal Output.
    # If it isn't available, the return of this funtion will be "not-installed", indicating that
        # Winget isn't installed/available on The System.
    if ($wingetExists) {
            # Check if Preview Version
            if ($wingetVersionFull.Contains("-preview")) {
                $wingetVersion = $wingetVersionFull.Trim("-preview")
                $wingetPreview = $true
            } else {
                $wingetVersion = $wingetVersionFull
                $wingetPreview = $false
            }

            # Check if Winget's Version is too old.
            $wingetCurrentVersion = [System.Version]::Parse($wingetVersion.Trim('v'))
            # Grabs the latest release of Winget from the Github API for version check process.
            $response = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/Winget-cli/releases/latest" -Method Get -ErrorAction Stop
            $wingetLatestVersion = [System.Version]::Parse(($response.tag_name).Trim('v')) #Stores version number of latest release.
            $wingetOutdated = $wingetCurrentVersion -lt $wingetLatestVersion
            Write-Host "===========================================" -ForegroundColor Green
            Write-Host "---        Winget is installed          ---" -ForegroundColor Green
            Write-Host "===========================================" -ForegroundColor Green
            Write-Host "Version: $wingetVersionFull" -ForegroundColor White

            if (!$wingetPreview) {
                Write-Host "    - Winget is a release version." -ForegroundColor Green
            } else {
                Write-Host "    - Winget is a preview version. Unexpected problems may occur." -ForegroundColor Yellow
            }

            if (!$wingetOutdated) {
                Write-Host "    - Winget is Up to Date" -ForegroundColor Green
                $status = "installed"
            } else {
                Write-Host "    - Winget is Out of Date" -ForegroundColor Red
                $status = "outdated"
            }
        } else {
            Write-Host "===========================================" -ForegroundColor Red
            Write-Host "---      Winget is not installed        ---" -ForegroundColor Red
            Write-Host "===========================================" -ForegroundColor Red
            $status = "not-installed"
        }
    }

    if ($choco) {
        if ((Get-Command -Name choco -ErrorAction Ignore) -and ($chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion)) {
            Write-Host "===========================================" -ForegroundColor Green
            Write-Host "---      Chocolatey is installed        ---" -ForegroundColor Green
            Write-Host "===========================================" -ForegroundColor Green
            Write-Host "Version: v$chocoVersion" -ForegroundColor White
            $status = "installed"
        } else {
            Write-Host "===========================================" -ForegroundColor Red
            Write-Host "---    Chocolatey is not installed      ---" -ForegroundColor Red
            Write-Host "===========================================" -ForegroundColor Red
            $status = "not-installed"
        }
    }

    return $status
}
