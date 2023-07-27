function Get-LatestHash {
    $shaUrl = ((Invoke-WebRequest $apiLatestUrl -UseBasicParsing | ConvertFrom-Json).assets | Where-Object { $_.name -match '^Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.txt$' }).browser_download_url
  
    $shaFile = Join-Path -Path $tempFolder -ChildPath 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.txt'
    $WebClient.DownloadFile($shaUrl, $shaFile)
  
    Get-Content $shaFile
  }

function Install-WinUtilWinget {
    
    <#
    
        .DESCRIPTION
        Function is meant to ensure winget is installed 
    
    #>
    Try{
        Write-Host "Checking if Winget is Installed..."
        if (Test-WinUtilPackageManager -winget) {
            #Checks if winget executable exists and if the Windows Version is 1809 or higher
            Write-Host "Winget Already Installed"
            return
        }

        #Gets the computer's information
        if ($null -eq $sync.ComputerInfo){
            $ComputerInfo = Get-ComputerInfo -ErrorAction Stop
        }
        Else {
            $ComputerInfo = $sync.ComputerInfo
        }

        if (($ComputerInfo.WindowsVersion) -lt "1809") {
            #Checks if Windows Version is too old for winget
            Write-Host "Winget is not supported on this version of Windows (Pre-1809)"
            return
        }

        Write-Host "Running Alternative Installer and Direct Installing"
        $ErrorActionPreference = "Stop"
        $apiLatestUrl = 'https://api.github.com/repos/microsoft/winget-cli/releases/latest'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Hide the progress bar of Invoke-WebRequest
        $oldProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'

        $desktopAppInstaller = @{
        fileName = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
        url      = $(((Invoke-WebRequest $apiLatestUrl -UseBasicParsing | ConvertFrom-Json).assets | Where-Object { $_.name -match '^Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle$' }).browser_download_url)
        hash     = $(Get-LatestHash)
        }

        $vcLibsUwp = @{
        fileName = 'Microsoft.VCLibs.x64.14.00.Desktop.appx'
        url      = 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
        hash     = '6602159c341bafea747d0edf15669ac72df8817299fbfaa90469909e06794256'
        }
        $uiLibs = @{
            nupkg = @{
                fileName = 'microsoft.ui.xaml.2.7.0.nupkg'
                url = 'https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.0'
                hash = "422FD24B231E87A842C4DAEABC6A335112E0D35B86FAC91F5CE7CF327E36A591"
            }
            uwp = @{
                fileName = 'Microsoft.UI.Xaml.2.7.appx'
            }
        }
        $uiLibs.uwp.file = $PWD.Path + '\' + $uiLibs.uwp.fileName
        $uiLibs.uwp.zipPath = '*/x64/*/' + $uiLibs.uwp.fileName

        $dependencies = @($desktopAppInstaller, $vcLibsUwp, $uiLibs.nupkg)

        foreach ($dependency in $dependencies) {
        $dependency.file = $dependency.fileName
        Invoke-WebRequest $dependency.url -OutFile $dependency.file
        }

        $uiLibs.nupkg.file = $PSScriptRoot + '\' + $uiLibs.nupkg.fileName
        Add-Type -Assembly System.IO.Compression.FileSystem
        $uiLibs.nupkg.zip = [IO.Compression.ZipFile]::OpenRead($uiLibs.nupkg.file)
        $uiLibs.nupkg.zipUwp = $uiLibs.nupkg.zip.Entries | Where-Object { $_.FullName -like $uiLibs.uwp.zipPath }
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($uiLibs.nupkg.zipUwp, $uiLibs.uwp.file, $true)
        $uiLibs.nupkg.zip.Dispose()

        Add-AppxPackage -Path $desktopAppInstaller.file -DependencyPath $vcLibsUwp.file,$uiLibs.uwp.file

        Remove-Item $desktopAppInstaller.file
        Remove-Item $vcLibsUwp.file
        Remove-Item $uiLibs.nupkg.file
        Remove-Item $uiLibs.uwp.file
        Write-Host "WinGet installed!" -ForegroundColor Green
        $ProgressPreference = $oldProgressPreference
        Update-EnvironmentVariables

        Write-Host "Winget Installed"
    }
    Catch{
        throw [WingetFailedInstall]::new('Failed to install')
    }
}
