function Get-WinUtilWingetLatest {
    [CmdletBinding()]
    param()

    <#
    .SYNOPSIS
        Uses GitHub API to check for the latest release of Winget.
    .DESCRIPTION
        This function first attempts to update WinGet using winget itself, then falls back to manual installation if needed.
    #>
    $ProgressPreference = "SilentlyContinue"
    $InformationPreference = 'Continue'

    try {
        $wingetCmd = Get-Command winget -ErrorAction Stop
        Write-Information "Attempting to update WinGet using WinGet..."
        $result = Start-Process -FilePath "`"$($wingetCmd.Source)`"" -ArgumentList "install -e --accept-source-agreements --accept-package-agreements Microsoft.AppInstaller" -Wait -NoNewWindow -PassThru
        if ($result.ExitCode -ne 0) {
            throw "WinGet update failed with exit code: $($result.ExitCode)"
        }
        return $true
    }
    catch {
        Write-Information "WinGet not found or update failed. Attempting to install from Microsoft Store..."
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
                return $true
            } else {
                throw "Installation failed with status: $($deploymentOperation.Status)"
            }
        }
        catch [System.Management.Automation.RuntimeException] {
            Write-Information "Windows Runtime components not available. Attempting manual download..."
            try {
                # Try to close any running WinGet processes
                Get-Process -Name "DesktopAppInstaller", "winget" -ErrorAction SilentlyContinue | ForEach-Object {
                    Write-Information "Stopping running WinGet process..."
                    $_.Kill()
                    Start-Sleep -Seconds 2
                }

                # Fallback to direct download from GitHub
                $apiUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
                $release = Invoke-RestMethod -Uri $apiUrl
                $msixBundleUrl = ($release.assets | Where-Object { $_.name -like "*.msixbundle" }).browser_download_url

                $tempFile = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller.msixbundle"
                Invoke-WebRequest -Uri $msixBundleUrl -OutFile $tempFile

                Add-AppxPackage -Path $tempFile -ErrorAction Stop
                Remove-Item $tempFile -Force

                Write-Information "Successfully installed WinGet from GitHub release"
                return $true
            }
            catch {
                Write-Error "Failed to install WinGet: $_"
                return $false
            }
        }
        catch {
            Write-Error "Failed to install WinGet: $_"
            return $false
        }
    }
}
