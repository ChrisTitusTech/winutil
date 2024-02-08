function Get-LatestHash {
    $shaUrl = ((Invoke-WebRequest $apiLatestUrl -UseBasicParsing | ConvertFrom-Json).assets | Where-Object { $_.name -match '^Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.txt$' }).browser_download_url

    $shaFile = Join-Path -Path $tempFolder -ChildPath 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.txt'
    $WebClient.DownloadFile($shaUrl, $shaFile)

    Get-Content $shaFile
}

function Install-WinUtilWinget {

    <#

    .SYNOPSIS
        Installs Winget if it is not already installed

    .DESCRIPTION
        This function will download the latest version of winget and install it. If winget is already installed, it will do nothing.
    #>
    Try{
        Write-Host "Checking if Winget is Installed..."
        if (Test-WinUtilPackageManager -winget) {
            # Checks if winget executable exists and if the Windows Version is 1809 or higher
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
            # Checks if Windows Version is too old for winget
            Write-Host "Winget is not supported on this version of Windows (Pre-1809)"
            return
        }

        Write-Host "Running Alternative Installer and Direct Installing"
        Start-Process -Verb runas -FilePath powershell.exe -ArgumentList "choco install winget"

        Write-Host "Winget Installed"
    }
    Catch{
        throw [WingetFailedInstall]::new('Failed to install')
    }
}