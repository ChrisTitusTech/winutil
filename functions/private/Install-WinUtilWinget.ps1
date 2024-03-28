function Install-WinUtilWinget {
    <#

    .SYNOPSIS
        Installs Winget if it is not already installed.

    .DESCRIPTION
        This function will download the latest version of Winget and install it. If Winget is already installed, it will do nothing.
    #>
    Try{
        Write-Host "Checking if Winget is Installed..."
        if (Test-WinUtilPackageManager -Winget) {
        # Checks if Winget executable exists and if the Windows Version is 1809 or higher
            Write-Host "Winget Already Installed"
            return
        }

        # Gets the computer's information
        if ($null -eq $sync.ComputerInfo){
            $ComputerInfo = Get-ComputerInfo -ErrorAction Stop
        }
        Else {
            $ComputerInfo = $sync.ComputerInfo
        }

        if (($ComputerInfo.WindowsVersion) -lt "1809") {
            # Checks if Windows Version is too old for Winget
            Write-Host "Winget is not supported on this version of Windows (Pre-1809)"
            return
        }

        if((Get-Command -Name choco -ErrorAction Ignore)) {
            # Checks if Chocolatey is present (In case it didn't install properly), and installs Winget with choco, if so.
            Write-Host "Chocolatey detected. Installing Winget via Chocolatey"
            Start-Process -Verb runas -FilePath powershell.exe -ArgumentList "choco install winget-cli"
            Write-Host "Winget Installed"
            Write-Output "Refreshing Environment Variables...`n"
            $ENV:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        }
        Else {
            # If Chocolatey doesn't exist, it will install Winget through more manual means.
            # Used part of my own script with some modification: ruxunderscore/windows-initialization
            Write-Host "Downloading Winget Prerequsites"
            Get-WinUtilWingetPrerequisites
            Write-Host "Downloading Winget and License File"
            Get-WinUtilWingetLatest
            Write-Host "Installing Winget w/ Prerequsites"
            Add-AppxProvisionedPackage -Online -PackagePath $ENV:TEMP\Microsoft.DesktopAppInstaller.msixbundle -DependencyPackagePath $ENV:TEMP\Microsoft.VCLibs.x64.Desktop.appx, $ENV:TEMP\Microsoft.UI.Xaml.x64.appx -LicensePath $ENV:TEMP\License1.xml
            Write-Host "Winget Installed"
            # Winget only needs a refresh of the environment variables to be used.
            Write-Output "Refreshing Environment Variables...`n"
            $ENV:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        }
    }
    Catch{
        throw [WingetFailedInstall]::new('Failed to install')
    }
}
