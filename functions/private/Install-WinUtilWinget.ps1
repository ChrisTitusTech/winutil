function Install-WinUtilWinget {
    <#

    .SYNOPSIS
        Installs Winget if it is not already installed.

    .DESCRIPTION
        This function will download the latest version of Winget and install it. If Winget is already installed, it will do nothing.
    #>
    $isWingetInstalled = Test-WinUtilPackageManager -winget

    try {
        if ($isWingetInstalled -eq "installed") {
            Write-Host "`nWinget is already installed.`r" -ForegroundColor Green
            return
        } elseif ($isWingetInstalled -eq "outdated") {
            Write-Host "`nWinget is Outdated. Continuing with install.`r" -ForegroundColor Yellow
        } else {
            Write-Host "`nWinget is not Installed. Continuing with install.`r" -ForegroundColor Red
        }


        # Gets the computer's information
        if ($null -eq $sync.ComputerInfo) {
            $ComputerInfo = Get-ComputerInfo -ErrorAction Stop
        } else {
            $ComputerInfo = $sync.ComputerInfo
        }

        if (($ComputerInfo.WindowsVersion) -lt "1809") {
            # Checks if Windows Version is too old for Winget
            Write-Host "Winget is not supported on this version of Windows (Pre-1809)" -ForegroundColor Red
            return
        }

        # Install Winget via GitHub method.
        # Used part of my own script with some modification: ruxunderscore/windows-initialization
        Write-Host "Downloading Winget and License File`r"
        Get-WinUtilWingetLatest
        Write-Host "Enabling NuGet and Module..."
        Install-PackageProvider -Name NuGet -Force
        Install-Module -Name Microsoft.WinGet.Client -Force
        # Winget only needs a refresh of the environment variables to be used.
        Write-Output "Refreshing Environment Variables...`n"
        $ENV:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    } catch {
        Write-Error "Failed to install Winget: $($_.Exception.Message)"
    }

}
