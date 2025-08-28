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

        Write-Host "Attempting to install/update Winget`r"
        try {
            $wingetCmd = Get-Command winget -ErrorAction Stop
            Write-Information "Attempting to update WinGet using WinGet..."
            $result = Start-Process -FilePath "`"$($wingetCmd.Source)`"" -ArgumentList "install -e --accept-source-agreements --accept-package-agreements Microsoft.AppInstaller" -Wait -NoNewWindow -PassThru
            if ($result.ExitCode -ne 0) {
                throw "WinGet update failed with exit code: $($result.ExitCode)"
            }
            Write-Output "Refreshing Environment Variables...`n"
            $ENV:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            return
        } catch {
            Write-Information "WinGet not found or update failed. Attempting to install from Microsoft Store..."
        }
        try {
            Write-Host "Attempting to repair WinGet using Repair-WinGetPackageManager..." -ForegroundColor Yellow

            # Check if Windows version supports Repair-WinGetPackageManager (24H2 and above)
            if ([System.Environment]::OSVersion.Version.Build -ge 26100) {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
                Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
                Install-Module "Microsoft.WinGet.Client" -Force
                Import-Module Microsoft.WinGet.Client
                Repair-WinGetPackageManager -Force -Latest -Verbose
                # Verify if repair was successful
                $wingetCmd = Get-Command winget -ErrorAction Stop
                Write-Host "WinGet repair successful!" -ForegroundColor Green
            } else {
                Write-Host "Repair-WinGetPackageManager is only available on Windows 24H2 and above. Your version doesn't support this method." -ForegroundColor Yellow
                throw "Windows version not supported for repair method"
            }

            Write-Output "Refreshing Environment Variables...`n"
            $ENV:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            return

        } catch {
            Write-Error "All installation methods failed. Unable to install WinGet."
            throw
        }
    } catch {
        Write-Error "An error occurred during WinGet installation: $_"
        throw
    }
}
