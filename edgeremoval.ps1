# Script Metadata
# Created by AveYo, source: https://raw.githubusercontent.com/AveYo/fox/main/Edge_Removal.bat
# Powershell Conversion and Refactor by Chris Titus Tech
# Updated By Taylor Christian Nesome 8/6/2024

# Define constants and initial configuration
$ScriptVersion = "2023.05.10"
$EdgeProcessesToShutdown = @('explorer', 'Widgets', 'widgetservice', 'msedgewebview2', 'MicrosoftEdge*', 'chredge', 'msedge', 'edge', 'msteams', 'msfamily', 'WebViewHost', 'Clipchamp')
$EdgeRemovalOptions = @{
    RemoveWin32 = @("Microsoft Edge", "Microsoft Edge Update")
    RemoveAppx = @("MicrosoftEdge")
    Skip = @() # Optional: @("DevTools")
    AlsoRemoveWebView = $false
}

# Set window title
$host.ui.RawUI.WindowTitle = "Edge Removal - Chris Titus Tech $ScriptVersion"

# Administrative Privileges Check
$privileges = @(
    'SeSecurityPrivilege',
    'SeTakeOwnershipPrivilege',
    'SeBackupPrivilege',
    'SeRestorePrivilege'
)

foreach ($privilege in $privileges) {
    [System.Diagnostics.Process]::SetPrivilege($privilege, 2)
}

# Define main function to remove Microsoft Edge components
function Remove-MicrosoftEdge {
    [CmdletBinding()]
    param()

    # Function to shutdown processes related to Microsoft Edge
    function Stop-EdgeProcesses {
        $EdgeProcessesToShutdown | ForEach-Object {
            Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue
        }
    }

    # Function to remove registry entries related to Microsoft Edge
    function Remove-EdgeRegistryEntries {
        # Clean up certain registry entries
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msedge.exe" -Recurse -ErrorAction SilentlyContinue
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ie_to_edge_stub.exe" -Recurse -ErrorAction SilentlyContinue
        Remove-Item -Path 'Registry::HKEY_Users\S-1-5-21*\Software\Classes\microsoft-edge' -Recurse -ErrorAction SilentlyContinue
        Remove-Item -Path 'Registry::HKEY_Users\S-1-5-21*\Software\Classes\MSEdgeHTM' -Recurse -ErrorAction SilentlyContinue

        # Create new registry entries
        $EdgeExecutablePath = ($env:ProgramFiles, ${env:ProgramFiles(x86)})[[Environment]::Is64BitOperatingSystem] + '\Microsoft\Edge\Application\msedge.exe'
        New-Item -Path "HKLM:\SOFTWARE\Classes\microsoft-edge\shell\open\command" -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\microsoft-edge\shell\open\command" -Name '(Default)' -Value "`"$EdgeExecutablePath`" --single-argument %%1" -Force -ErrorAction SilentlyContinue

        New-Item -Path "HKLM:\SOFTWARE\Classes\MSEdgeHTM\shell\open\command" -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\MSEdgeHTM\shell\open\command" -Name '(Default)' -Value "`"$EdgeExecutablePath`" --single-argument %%1" -Force -ErrorAction SilentlyContinue
    }

    # Function to remove Microsoft Edge AppX packages
    function Remove-EdgeAppxPackages {
        $EdgeRemovalOptions.RemoveAppx | ForEach-Object {
            # Remove provisioned packages
            Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like "*$_*" -and $EdgeRemovalOptions.Skip -notcontains $_.PackageName } | Remove-AppxProvisionedPackage -Online -AllUsers -ErrorAction SilentlyContinue

            # Remove installed packages
            Get-AppxPackage -AllUsers | Where-Object { $_.PackageFullName -like "*$_*" -and $EdgeRemovalOptions.Skip -notcontains $_.PackageFullName } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        }
    }

    # Function to remove unnecessary shortcuts
    function Remove-Shortcuts {
        $shortcutPaths = @(
            "$env:Public\Desktop\Microsoft Edge.lnk",
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
        )

        $shortcutPaths | ForEach-Object {
            if (Test-Path $_) {
                Remove-Item -Path $_ -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # Function to configure Edge policies
    function Configure-EdgePolicies {
        $edgePolicy = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
        if (-not (Test-Path $edgePolicy)) {
            New-Item -Path $edgePolicy -Force | Out-Null
        }

        $edgePrefs = @{
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

        foreach ($entryType in $edgePrefs.Keys) {
            foreach ($prefName in $edgePrefs[$entryType].Keys) {
                Set-ItemProperty -Path $edgePolicy -Name $prefName -Value $edgePrefs[$entryType][$prefName] -Type $entryType -Force
            }
        }
    }

    # Function to remove backup files and folders
    function Remove-BackupFiles {
        $foldersToSearch = @('LocalApplicationData', 'ProgramFilesX86', 'ProgramFiles') | ForEach-Object {
            [Environment]::GetFolderPath($_)
        }

        $bhoFiles = @()
        $edges = @()

        foreach ($folder in $foldersToSearch) {
            $bhoFiles += Get-ChildItem -Path "$folder\Microsoft\Edge*\ie_to_edge_stub.exe" -Recurse -ErrorAction SilentlyContinue
            $edges += Get-ChildItem -Path "$folder\Microsoft\Edge*\setup.exe" -Recurse -ErrorAction SilentlyContinue |
                      Where-Object { $_.FullName -notlike '*EdgeWebView*' }
        }

        $destinationDir = "$env:SystemDrive\Scripts"
        New-Item -Path $destinationDir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

        foreach ($bhoFile in $bhoFiles) {
            if (Test-Path $bhoFile) {
                try {
                    Copy-Item -Path $bhoFile -Destination "$destinationDir\ie_to_edge_stub.exe" -Force
                } catch { }
            }
        }
    }

    # Run all functions
    try {
        Stop-EdgeProcesses
        Remove-EdgeRegistryEntries
        Remove-EdgeAppxPackages
        Remove-Shortcuts
        Configure-EdgePolicies
        Remove-BackupFiles
        Write-Output "Microsoft Edge components have been successfully removed."
    } catch {
        Write-Error "Failed to remove Microsoft Edge components: $_"
    }
}

# Execute the main function
Remove-MicrosoftEdge
