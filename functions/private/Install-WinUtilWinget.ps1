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
            # Try to close any running WinGet processes
            Get-Process -Name "DesktopAppInstaller", "winget" -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Information "Stopping running WinGet process..."
                $_.Kill()
                Start-Sleep -Seconds 2
            }

            # Try to load Windows Runtime assemblies more reliably
            $null = [System.Runtime.WindowsRuntime.WindowsRuntimeSystemExtensions]
            Add-Type -AssemblyName System.Runtime.WindowsRuntime

            # Load required assemblies from Windows SDK
            $null = @(
                [Windows.Management.Deployment.PackageManager, Windows.Management.Deployment, ContentType = WindowsRuntime]
                [Windows.Foundation.Uri, Windows.Foundation, ContentType = WindowsRuntime]
                [Windows.Management.Deployment.DeploymentOptions, Windows.Management.Deployment, ContentType = WindowsRuntime]
            )

            # Initialize PackageManager
            $packageManager = New-Object Windows.Management.Deployment.PackageManager

            # Rest of the Microsoft Store installation logic
            $appxPackage = "https://aka.ms/getwinget"
            $uri = New-Object Windows.Foundation.Uri($appxPackage)
            $deploymentOperation = $packageManager.AddPackageAsync($uri, $null, "Add")

            # Add timeout check for deployment operation
            $timeout = 300
            $timer = [System.Diagnostics.Stopwatch]::StartNew()

            while ($deploymentOperation.Status -eq 0) {
                if ($timer.Elapsed.TotalSeconds -gt $timeout) {
                    throw "Installation timed out after $timeout seconds"
                }
                Start-Sleep -Milliseconds 100
            }

            if ($deploymentOperation.Status -eq 1) {
                Write-Information "Successfully installed WinGet from Microsoft Store"
                Write-Output "Refreshing Environment Variables...`n"
                $ENV:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                return
            } else {
                throw "Installation failed with status: $($deploymentOperation.Status)"
            }
        } catch {
            Write-Information "Microsoft Store installation failed. Attempting to install from Nuget..."
        }
        try {
            ## Nuget Method
            Write-Host "Enabling NuGet and Module..."
                # Enable TLS 1.2 for the PowerShell session
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

                # Try to register the NuGet package source if not present
                if (-not (Get-PackageSource -Name "NuGet" -ErrorAction SilentlyContinue)) {
                    Register-PackageSource -Name "NuGet" -Location "https://www.nuget.org/api/v2" -ProviderName NuGet -Force
                }

                # Install NuGet provider with error handling
                try {
                    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -ErrorAction Stop
                } catch {
                    Write-Warning "Failed to install NuGet provider through standard method. Trying alternative approach..."
                    Install-PackageProvider -Name NuGet -Source "https://www.powershellgallery.com/api/v2" -Force -Confirm:$false
            }
            Install-Module -Name Microsoft.WinGet.Client -Confirm:$false -Force

            # Check if WinGet was installed successfully through NuGet
            $wingetCmd = Get-Command winget -ErrorAction Stop
            Write-Information "Successfully installed WinGet through NuGet"
            Write-Output "Refreshing Environment Variables...`n"
            $ENV:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            return
        } catch {
            Write-Warning "NuGet installation failed. Attempting to install from GitHub..."
        }
        # GitHub fallback installation method
        $releases_url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
        $asset = (Invoke-RestMethod -Uri $releases_url).assets | 
            Where-Object { $_.name -match "\.msixbundle$" } | 
            Select-Object -First 1
        
        $download_url = $asset.browser_download_url
        $output_path = Join-Path $env:TEMP $asset.name
        
        Invoke-WebRequest -Uri $download_url -OutFile $output_path
        Add-AppxPackage -Path $output_path -ErrorAction Stop
        
        # Verify installation
        $wingetCmd = Get-Command winget -ErrorAction Stop
        Write-Information "Successfully installed WinGet through GitHub"
        Write-Output "Refreshing Environment Variables...`n"
        $ENV:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        return
    } catch {
        Write-Error "All installation methods failed. Unable to install WinGet."
        throw
    }
}
