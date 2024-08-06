# Script Metadata
# Created by AveYo, source: https://raw.githubusercontent.com/AveYo/fox/main/Edge_Removal.bat
# Powershell Conversion and Refactor by Chris Titus Tech
# Updated By Taylor Christian Nesome 8/6/2024

# Define constants and initial configuration
<#
.SYNOPSIS
    This script removes Microsoft Edge and related components from the system.

.DESCRIPTION
    This script performs the following tasks:
    - Terminates Edge-related processes.
    - Removes registry entries associated with Microsoft Edge.
    - Uninstalls Edge-related AppX packages.
    - Cleans up shortcut files.
    - Configures Edge policy settings to prevent reinstallation.

.NOTES
    Updated by Taylor Christian Newsome
    Version: 2024.08.06
#>

# Define constants and initial configuration
$ScriptVersion = "2024.08.06"
$EdgeProcessesToShutdown = @('explorer', 'Widgets', 'widgetservice', 'msedgewebview2', 'MicrosoftEdge*', 'chredge', 'msedge', 'edge', 'msteams', 'msfamily', 'WebViewHost', 'Clipchamp')
$EdgeRemovalOptions = @{
    RemoveWin32 = @("Microsoft Edge", "Microsoft Edge Update")
    RemoveAppx = @("MicrosoftEdge")
    Skip = @() # Optional: @("DevTools")
    AlsoRemoveWebView = $false
}

# Function to check if the script is running with administrative privileges
function Test-Admin {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "The script must be run as an Administrator."
        exit 1
    }
}

# Function to stop Edge-related processes
function Stop-EdgeProcesses {
    param([string[]]$ProcessesToStop)
    foreach ($process in $ProcessesToStop) {
        try {
            Stop-Process -Name $process -Force -ErrorAction Stop
            Write-Output "Successfully stopped process: $process"
        } catch {
            Write-Error "Failed to stop process: $process. $_"
        }
    }
}

# Function to remove registry entries related to Microsoft Edge
function Remove-EdgeRegistryEntries {
    param([string[]]$RegistryPaths)
    foreach ($path in $RegistryPaths) {
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
            Write-Output "Successfully removed registry path: $path"
        } catch {
            Write-Error "Failed to remove registry path: $path. $_"
        }
    }
}

# Function to remove Microsoft Edge AppX packages
function Remove-EdgeAppxPackages {
    param([string[]]$AppxPackagesToRemove)
    $provisionedPackages = Get-AppxProvisionedPackage -Online
    foreach ($package in $AppxPackagesToRemove) {
        try {
            $packagesToRemove = $provisionedPackages | Where-Object { $_.DisplayName -like "*$package*" }
            foreach ($pkg in $packagesToRemove) {
                Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -ErrorAction Stop
                Write-Output "Successfully removed provisioned package: $pkg.DisplayName"
            }

            $installedPackages = Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like "*$package*" }
            foreach ($pkg in $installedPackages) {
                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                Write-Output "Successfully removed installed package: $pkg.PackageFullName"
            }
        } catch {
            Write-Error "Failed to remove AppX package: $package. $_"
        }
    }
}

# Function to remove shortcuts related to Microsoft Edge
function Remove-EdgeShortcuts {
    param([string[]]$ShortcutPaths)
    foreach ($path in $ShortcutPaths) {
        if (Test-Path $path) {
            try {
                Remove-Item -Path $path -Force -ErrorAction Stop
                Write-Output "Successfully removed shortcut: $path"
            } catch {
                Write-Error "Failed to remove shortcut: $path. $_"
            }
        }
    }
}

# Function to configure Edge policy settings
function Configure-EdgePolicy {
    param([hashtable]$PolicySettings)
    $edgePolicyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    if (-not (Test-Path $edgePolicyPath)) {
        try {
            New-Item -Path $edgePolicyPath -Force | Out-Null
            Write-Output "Created Edge policy registry path: $edgePolicyPath"
        } catch {
            Write-Error "Failed to create Edge policy registry path: $edgePolicyPath. $_"
        }
    }

    foreach ($entryType in $PolicySettings.Keys) {
        foreach ($prefName in $PolicySettings[$entryType].Keys) {
            try {
                Set-ItemProperty -Path $edgePolicyPath -Name $prefName -Value $PolicySettings[$entryType][$prefName] -Type $entryType -Force
                Write-Output "Successfully set Edge policy: $prefName = $($PolicySettings[$entryType][$prefName])"
            } catch {
                Write-Error "Failed to set Edge policy: $prefName. $_"
            }
        }
    }
}

# Main execution
try {
    Test-Admin
    Stop-EdgeProcesses -ProcessesToStop $EdgeProcessesToShutdown
    Remove-EdgeRegistryEntries -RegistryPaths @(
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msedge.exe",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ie_to_edge_stub.exe",
        "Registry::HKEY_Users\S-1-5-21*\Software\Classes\microsoft-edge",
        "Registry::HKEY_Users\S-1-5-21*\Software\Classes\MSEdgeHTM"
    )
    Remove-EdgeAppxPackages -AppxPackagesToRemove $EdgeRemovalOptions.RemoveAppx
    Remove-EdgeShortcuts -ShortcutPaths @(
        "$env:Public\Desktop\Microsoft Edge.lnk",
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
    )
    Configure-EdgePolicy -PolicySettings @{
        'Dword' = @{
            'BrowserReplacementEnabled' = 1
            'HideFirstRunExperience' = 1
            'HideImportEdgeFavoritesPrompt' = 1
            'HideSyncSetupExperience' = 1
            'FavoritesBarVisibility' = 1
        }
        'String' = @{
            'AutoplayAllowed' = 'AllowOnce'
        }
    }
    Write-Output "Microsoft Edge components have been successfully removed."
} catch {
    Write-Error "An error occurred during execution: $_"
}

Remove-MicrosoftEdge
