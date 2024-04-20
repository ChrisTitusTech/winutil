# Script Metadata
# Created by AveYo, source: https://raw.githubusercontent.com/AveYo/fox/main/Edge_Removal.bat
# Powershell Conversion and Refactor done by Chris Titus Tech

# Initial Configuration
$host.ui.RawUI.WindowTitle = 'Edge Removal - Chris Titus Tech 2023.05.10'
$remove_win32 = @("Microsoft Edge", "Microsoft Edge Update")
$remove_appx = @("MicrosoftEdge")
$skip = @() # Optional: @("DevTools")

$also_remove_webview = 0
if ($also_remove_webview -eq 1) {
    $remove_win32 += "Microsoft EdgeWebView"
    $remove_appx += "WebExperience", "Win32WebViewHost"
}

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

# Edge Removal Procedures
$processesToShutdown = @(
    'explorer', 'Widgets', 'widgetservice', 'msedgewebview2', 'MicrosoftEdge*', 'chredge',
    'msedge', 'edge', 'msteams', 'msfamily', 'WebViewHost', 'Clipchamp'
)

Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
$processesToShutdown | ForEach-Object {
    Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue
}

$MS = ($env:ProgramFiles, ${env:ProgramFiles(x86)})[[Environment]::Is64BitOperatingSystem] + '\Microsoft\Edge\Application\msedge.exe'

Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msedge.exe" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ie_to_edge_stub.exe" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path 'Registry::HKEY_Users\S-1-5-21*\Software\Classes\microsoft-edge' -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path 'Registry::HKEY_Users\S-1-5-21*\Software\Classes\MSEdgeHTM' -Recurse -ErrorAction SilentlyContinue

New-Item -Path "HKLM:\SOFTWARE\Classes\microsoft-edge\shell\open\command" -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\microsoft-edge\shell\open\command" -Name '(Default)' -Value "`"$MS`" --single-argument %%1" -Force -ErrorAction SilentlyContinue

New-Item -Path "HKLM:\SOFTWARE\Classes\MSEdgeHTM\shell\open\command" -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\MSEdgeHTM\shell\open\command" -Name '(Default)' -Value "`"$MS`" --single-argument %%1" -Force -ErrorAction SilentlyContinue

$registryPaths = @('HKLM:\SOFTWARE\Policies', 'HKLM:\SOFTWARE', 'HKLM:\SOFTWARE\WOW6432Node')
$edgeProperties = @('InstallDefault', 'Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}', 'Install{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}')
foreach ($path in $registryPaths) {
    foreach ($prop in $edgeProperties) {
        Remove-ItemProperty -Path "$path\Microsoft\EdgeUpdate" -Name $prop -Force -ErrorAction SilentlyContinue
    }
}

$edgeupdate = 'Microsoft\EdgeUpdate\Clients\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}'
$webvupdate = 'Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
$on_actions = @('on-os-upgrade', 'on-logon', 'on-logon-autolaunch', 'on-logon-startup-boost')
$registryBases = @('HKLM:\SOFTWARE', 'HKLM:\SOFTWARE\Wow6432Node')
foreach ($base in $registryBases) {
    foreach ($launch in $on_actions) {
        Remove-Item -Path "$base\$edgeupdate\Commands\$launch" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$base\$webvupdate\Commands\$launch" -Force -ErrorAction SilentlyContinue
    }
}

$registryPaths = @('HKCU:', 'HKLM:')
$nodes = @('', '\Wow6432Node')
foreach ($regPath in $registryPaths) {
    foreach ($node in $nodes) {
        foreach ($i in $remove_win32) {
            Remove-ItemProperty -Path "$regPath\SOFTWARE${node}\Microsoft\Windows\CurrentVersion\Uninstall\$i" -Name 'NoRemove' -Force -ErrorAction SilentlyContinue
            New-Item -Path "$regPath\SOFTWARE${node}\Microsoft\EdgeUpdateDev" -Force | Out-Null
            Set-ItemProperty -Path "$regPath\SOFTWARE${node}\Microsoft\EdgeUpdateDev" -Name 'AllowUninstall' -Value 1 -Type Dword -Force
        }
    }
}

$foldersToSearch = @('LocalApplicationData', 'ProgramFilesX86', 'ProgramFiles') | ForEach-Object {
    [Environment]::GetFolderPath($_)
}

$edges = @()
$bhoFiles = @()

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

## Work on Appx Removals
$provisioned = Get-AppxProvisionedPackage -Online
$appxpackage = Get-AppxPackage -AllUsers
$eol = @()

$store = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Store'
$storeP = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Store\InstalledApplications'
foreach ($app in $appxpackage) {
    $name = $app.Name
    if ($app.Name -eq "Microsoft.Edge") {
        $eol += $name
    } elseif ($app.Name -eq "Microsoft.EdgeBeta" -or $app.Name -eq "Microsoft.EdgeDev" -or $app.Name -eq "Microsoft.EdgeCanary" -or $app.Name -eq "Microsoft.MicrosoftEdge") {
        $eol += $name
    }
}

$eolApps = $provisioned | Where-Object { $eol -contains $_.DisplayName }

foreach ($edge in $eolApps) {
    $edgeName = $edge.DisplayName
    if (-not ($skip -contains $edgeName)) {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $edgeName -ErrorAction SilentlyContinue
        } catch { }
    }
}

foreach ($edge in $appxpackage) {
    $edgeName = $edge.Name
    if ($eol -contains $edgeName) {
        if (-not ($skip -contains $edgeName)) {
            try {
                Remove-AppxPackage -Package $edgeName -AllUsers -ErrorAction SilentlyContinue
            } catch { }
        }
    }
}

## Redirect shortcuts
$shortcut_path = "$env:Public\Desktop"
$shortcut_file = 'Microsoft Edge.lnk'
$full_path = Join-Path -Path $shortcut_path -ChildPath $shortcut_file

if (Test-Path $full_path) {
    Remove-Item -Path $full_path -Force -ErrorAction SilentlyContinue
}

$shortcut_path = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
$shortcut_file = 'Microsoft Edge.lnk'
$full_path = Join-Path -Path $shortcut_path -ChildPath $shortcut_file

if (Test-Path $full_path) {
    Remove-Item -Path $full_path -Force -ErrorAction SilentlyContinue
}

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

# Output Results
Write-Host "Edge Removal Complete" -ForegroundColor Green

# Define constants and initial configuration
$ScriptVersion = "2023.05.10"
$EdgeProcessesToShutdown = @('explorer', 'Widgets', 'widgetservice', 'msedgewebview2', 'MicrosoftEdge*', 'chredge', 'msedge', 'edge', 'msteams', 'msfamily', 'WebViewHost', 'Clipchamp')
$EdgeRemovalOptions = @{
    RemoveWin32 = @("Microsoft Edge", "Microsoft Edge Update")
    RemoveAppx = @("MicrosoftEdge")
    Skip = @() # Optional: @("DevTools")
    AlsoRemoveWebView = $false
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

    # Function to remove Microsoft Edge processes, registry entries, and AppX packages
    try {
        Stop-EdgeProcesses
        Remove-EdgeRegistryEntries
        Remove-EdgeAppxPackages
        Write-Output "Microsoft Edge components have been successfully removed."
    } catch {
        Write-Error "Failed to remove Microsoft Edge components: $_"
    }
}

# Execute the main function
Remove-MicrosoftEdge