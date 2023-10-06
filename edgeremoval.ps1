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

# Get the 'SetPrivilege' method from System.Diagnostics.Process type
$setPrivilegeMethod = [System.Diagnostics.Process].GetMethod('SetPrivilege', [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Static)

# List of privileges to set
$privileges = @(
    'SeSecurityPrivilege',
    'SeTakeOwnershipPrivilege',
    'SeBackupPrivilege',
    'SeRestorePrivilege'
)

# Invoke the method for each privilege
foreach ($privilege in $privileges) {
    $setPrivilegeMethod.Invoke($null, @($privilege, 2))
}

# Edge Removal Procedures

# Define processes to shut down
$processesToShutdown = @(
    'explorer', 'Widgets', 'widgetservice', 'msedgewebview2', 'MicrosoftEdge*', 'chredge',
    'msedge', 'edge', 'msteams', 'msfamily', 'WebViewHost', 'Clipchamp'
)

# Kill explorer process
Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue

# Kill the processes from the list
$processesToShutdown | ForEach-Object {
    Stop-Process -Name $_ -Force -ErrorAction SilentlyContinue
}

# Set path for Edge executable
$MS = ($env:ProgramFiles, ${env:ProgramFiles(x86)})[[Environment]::Is64BitOperatingSystem] + '\Microsoft\Edge\Application\msedge.exe'

# Clean up certain registry entries
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\msedge.exe" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ie_to_edge_stub.exe" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path 'Registry::HKEY_Users\S-1-5-21*\Software\Classes\microsoft-edge' -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path 'Registry::HKEY_Users\S-1-5-21*\Software\Classes\MSEdgeHTM' -Recurse -ErrorAction SilentlyContinue

# Create new registry entries
New-Item -Path "HKLM:\SOFTWARE\Classes\microsoft-edge\shell\open\command" -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\microsoft-edge\shell\open\command" -Name '(Default)' -Value "`"$MS`" --single-argument %%1" -Force -ErrorAction SilentlyContinue

New-Item -Path "HKLM:\SOFTWARE\Classes\MSEdgeHTM\shell\open\command" -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\MSEdgeHTM\shell\open\command" -Name '(Default)' -Value "`"$MS`" --single-argument %%1" -Force -ErrorAction SilentlyContinue

# Remove certain registry properties
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

# Clear specific registry keys
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

# Locate setup.exe and ie_to_edge_stub.exe
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

# Create directory and copy ie_to_edge_stub.exe to it
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

# Retrieve AppX provisioned packages and all AppX packages
$provisioned = Get-AppxProvisionedPackage -Online
$appxpackage = Get-AppxPackage -AllUsers

# Initialize empty array for EndOfLife packages
$eol = @()

# Define user SIDs and retrieve them from the registry
$store = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
$users = @('S-1-5-18')
if (Test-Path $store) {
    $users += (Get-ChildItem $store -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -like '*S-1-5-21*' }).PSChildName
}

# Process AppX packages for removal
foreach ($choice in $remove_appx) {
    if ([string]::IsNullOrWhiteSpace($choice)) { continue }

    # Process provisioned packages
    $provisioned | Where-Object { $_.PackageName -like "*$choice*" } | ForEach-Object {
        if ($skip -Contains $_.PackageName) { return }

        $PackageName = $_.PackageName
        $PackageFamilyName = ($appxpackage | Where-Object { $_.Name -eq $_.DisplayName }).PackageFamilyName 

        # Add registry entries
        New-Item -Path "$store\Deprovisioned\$PackageFamilyName" -Force -ErrorAction SilentlyContinue | Out-Null
        $users | ForEach-Object {
            New-Item -Path "$store\EndOfLife\$_\$PackageName" -Force -ErrorAction SilentlyContinue | Out-Null
        }
        $eol += $PackageName

        # Modify non-removable app policy and remove package
        dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 | Out-Null
        Remove-AppxProvisionedPackage -PackageName $PackageName -Online -AllUsers | Out-Null
    }

    # Process all AppX packages
    $appxpackage | Where-Object { $_.PackageFullName -like "*$choice*" } | ForEach-Object {
        if ($skip -Contains $_.PackageFullName) { return }

        $PackageFullName = $_.PackageFullName

        # Add registry entries
        New-Item -Path "$store\Deprovisioned\$_.PackageFamilyName" -Force -ErrorAction SilentlyContinue | Out-Null
        $users | ForEach-Object {
            New-Item -Path "$store\EndOfLife\$_\$PackageFullName" -Force -ErrorAction SilentlyContinue | Out-Null
        }
        $eol += $PackageFullName

        # Modify non-removable app policy and remove package
        dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 | Out-Null
        Remove-AppxPackage -Package $PackageFullName -AllUsers | Out-Null
    }
}

## Run Edge setup uninstaller

foreach ($setup in $edges) {
    if (Test-Path $setup) {
        $target = if ($setup -like '*EdgeWebView*') { "--msedgewebview" } else { "--msedge" }
        
        $removalArgs = "--uninstall $target --system-level --verbose-logging --force-uninstall"
        
        Write-Host "$setup $removalArgs"
        
        try {
            Start-Process -FilePath $setup -ArgumentList $removalArgs -Wait
        } catch {
            # You may want to add logging or other error handling here.
        }
        
        while ((Get-Process -Name 'setup', 'MicrosoftEdge*' -ErrorAction SilentlyContinue).Path -like '*\Microsoft\Edge*') {
            Start-Sleep -Seconds 3
        }
    }
}

## Cleanup

# Define necessary paths and variables
$edgePaths = $env:ProgramFiles, ${env:ProgramFiles(x86)}
$appDataPath = [Environment]::GetFolderPath('ApplicationData')

# Uninstall Microsoft Edge Update
foreach ($path in $edgePaths) {
    $edgeUpdateExe = "$path\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe"
    if (Test-Path $edgeUpdateExe) {
        Write-Host $edgeUpdateExe /uninstall
        Start-Process -FilePath $edgeUpdateExe -ArgumentList '/uninstall' -Wait
        while ((Get-Process -Name 'setup','MicrosoftEdge*' -ErrorAction SilentlyContinue).Path -like '*\Microsoft\Edge*') {
            Start-Sleep -Seconds 3
        }
        if ($also_remove_webview -eq 1) {
            foreach ($regPath in 'HKCU:', 'HKLM:') {
                foreach ($node in '', '\Wow6432Node') {
                    Remove-Item -Path "$regPath\SOFTWARE$node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
            Remove-Item -Path "$path\Microsoft\EdgeUpdate" -Recurse -Force -ErrorAction SilentlyContinue
            Unregister-ScheduledTask -TaskName 'MicrosoftEdgeUpdate*' -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
}

# Remove Edge shortcuts
Remove-Item -Path "$appDataPath\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Tombstones\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$appDataPath\Microsoft\Internet Explorer\Quick Launch\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue

# Revert settings related to Microsoft Edge
foreach ($sid in $users) {
    foreach ($packageName in $eol) {
        Remove-Item -Path "$store\EndOfLife\$sid\$packageName" -Force -ErrorAction SilentlyContinue
    }
}

# Set policies to prevent unsolicited reinstalls of Microsoft Edge
$registryPaths = @('HKLM:\SOFTWARE\Policies', 'HKLM:\SOFTWARE', 'HKLM:\SOFTWARE\WOW6432Node')
$edgeUpdatePolicies = @{
    'InstallDefault'                     = 0;
    'Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}' = 0;
    'Install{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}' = 1;
    'DoNotUpdateToEdgeWithChromium'      = 1;
}

foreach ($path in $registryPaths) {
    New-Item -Path "$path\Microsoft\EdgeUpdate" -Force -ErrorAction SilentlyContinue | Out-Null
    foreach ($policy in $edgeUpdatePolicies.GetEnumerator()) {
        Set-ItemProperty -Path "$path\Microsoft\EdgeUpdate" -Name $policy.Key -Value $policy.Value -Type Dword -Force
    }
}

$edgeUpdateActions = @('on-os-upgrade', 'on-logon', 'on-logon-autolaunch', 'on-logon-startup-boost')
$edgeUpdateClients = @(
    'Microsoft\EdgeUpdate\Clients\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}',
    'Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
)
foreach ($client in $edgeUpdateClients) {
    foreach ($action in $edgeUpdateActions) {
        foreach ($regBase in 'HKLM:\SOFTWARE', 'HKLM:\SOFTWARE\Wow6432Node') {
            $regPath = "$regBase\$client\Commands\$action"
            New-Item -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null
            Set-ItemProperty -Path $regPath -Name 'CommandLine' -Value 'systray.exe' -Force
        }
    }
}

## Redirect Edge Shortcuts

# Define Microsoft Edge Paths
$MSEP = ($env:ProgramFiles, ${env:ProgramFiles(x86)})[[Environment]::Is64BitOperatingSystem] + '\Microsoft\Edge\Application'
$IFEO = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
$MIN = ('--headless', '--width 1 --height 1')[([environment]::OSVersion.Version.Build) -gt 25179]
$CMD = "$env:systemroot\system32\conhost.exe $MIN"
$DIR = "$env:SystemDrive\Scripts"

# Setup Microsoft Edge Registry Entries
New-Item -Path "HKLM:\SOFTWARE\Classes\microsoft-edge\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\microsoft-edge" -Name '(Default)' -Value 'URL:microsoft-edge' -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\microsoft-edge" -Name 'URL Protocol' -Value '' -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\microsoft-edge" -Name 'NoOpenWith' -Value '' -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\microsoft-edge\shell\open\command" -Name '(Default)' -Value "`"$DIR\ie_to_edge_stub.exe`" %1" -Force

# Setup MSEdgeHTM Registry Entries
New-Item -Path "HKLM:\SOFTWARE\Classes\MSEdgeHTM\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\MSEdgeHTM" -Name 'NoOpenWith' -Value '' -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\MSEdgeHTM\shell\open\command" -Name '(Default)' -Value "`"$DIR\ie_to_edge_stub.exe`" %1" -Force

# Setup Image File Execution Options for Edge and Edge WebView
$exeSettings = @(
    @{ ExeName = 'ie_to_edge_stub.exe'; Debugger = "$CMD $DIR\OpenWebSearch.cmd"; FilterPath = "$DIR\ie_to_edge_stub.exe" },
    @{ ExeName = 'msedge.exe'; Debugger = "$CMD $DIR\OpenWebSearch.cmd"; FilterPath = "$MSEP\msedge.exe" }
)

foreach ($setting in $exeSettings) {
    New-Item -Path "$IFEO\$($setting.ExeName)\0" -Force | Out-Null
    Set-ItemProperty -Path "$IFEO\$($setting.ExeName)" -Name 'UseFilter' -Value 1 -Type Dword -Force
    Set-ItemProperty -Path "$IFEO\$($setting.ExeName)\0" -Name 'FilterFullPath' -Value $setting.FilterPath -Force
    Set-ItemProperty -Path "$IFEO\$($setting.ExeName)\0" -Name 'Debugger' -Value $setting.Debugger -Force
}

# Write OpenWebSearch Batch Script
$OpenWebSearch = @'
@title OpenWebSearch Redux & echo off & set ?= open start menu web search, widgets links or help in your chosen browser - by AveYo
for /f %%E in ('"prompt $E$S& for %%e in (1) do rem"') do echo;%%E[2t 2>nul & rem AveYo: minimize prompt
call :reg_var "HKCU\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice" ProgID ProgID
if /i "%ProgID%" equ "MSEdgeHTM" echo;Default browser is set to Edge! Change it or remove OpenWebSearch script. & pause & exit /b
call :reg_var "HKCR\%ProgID%\shell\open\command" "" Browser
set Choice=& for %%. in (%Browser%) do if not defined Choice set "Choice=%%~."
call :reg_var "HKCR\MSEdgeMHT\shell\open\command" "" FallBack
set "Edge=" & for %%. in (%FallBack%) do if not defined Edge set "Edge=%%~."
set "URI=" & set "URL=" & set "NOOP=" & set "PassTrough=%Edge:msedge=edge%"
set "CLI=%CMDCMDLINE:"=``% "
if defined CLI set "CLI=%CLI:*ie_to_edge_stub.exe`` =%"
if defined CLI set "CLI=%CLI:*ie_to_edge_stub.exe =%"
if defined CLI set "CLI=%CLI:*msedge.exe`` =%"
if defined CLI set "CLI=%CLI:*msedge.exe =%"
set "FIX=%CLI:~-1%"
if defined CLI if "%FIX%"==" " set "CLI=%CLI:~0,-1%"
if defined CLI set "RED=%CLI:microsoft-edge=%"
if defined CLI set "URL=%CLI:http=%"
if defined CLI set "ARG=%CLI:``="%"
if "%CLI%" equ "%RED%" (set NOOP=1) else if "%CLI%" equ "%URL%" (set NOOP=1)
if defined NOOP if exist "%PassTrough%" start "" "%PassTrough%" %ARG%
if defined NOOP exit /b
set "URL=%CLI:*microsoft-edge=%"
set "URL=http%URL:*http=%"
set "FIX=%URL:~-2%"
if defined URL if "%FIX%"=="``" set "URL=%URL:~0,-2%"
call :dec_url
start "" "%Choice%" "%URL%"
exit

:reg_var [USAGE] call :reg_var "HKCU\Volatile Environment" value-or-"" variable [extra options]
set {var}=& set {reg}=reg query "%~1" /v %2 /z /se "," /f /e& if %2=="" set {reg}=reg query "%~1" /ve /z /se "," /f /e
for /f "skip=2 tokens=* delims=" %%V in ('%{reg}% %4 %5 %6 %7 %8 %9 2^>nul') do if not defined {var} set "{var}=%%V"
if not defined {var} (set {reg}=& set "%~3="& exit /b) else if %2=="" set "{var}=%{var}:*)    =%"& rem AveYo: v3
if not defined {var} (set {reg}=& set "%~3="& exit /b) else set {reg}=& set "%~3=%{var}:*)    =%"& set {var}=& exit /b

:dec_url brute url percent decoding by AveYo
set ".=%URL:!=}%"&setlocal enabledelayedexpansion& rem brute url percent decoding
set ".=!.:%%={!" &set ".=!.:{3A=:!" &set ".=!.:{2F=/!" &set ".=!.:{3F=?!" &set ".=!.:{23=#!" &set ".=!.:{5B=[!" &set ".=!.:{5D=]!"
set ".=!.:{40=@!"&set ".=!.:{21=}!" &set ".=!.:{24=$!" &set ".=!.:{26=&!" &set ".=!.:{27='!" &set ".=!.:{28=(!" &set ".=!.:{29=)!"
set ".=!.:{2A=*!"&set ".=!.:{2B=+!" &set ".=!.:{2C=,!" &set ".=!.:{3B=;!" &set ".=!.:{3D==!" &set ".=!.:{25=%%!"&set ".=!.:{20= !"
set ".=!.:{=%%!" &rem set ",=!.:%%=!" & if "!,!" neq "!.!" endlocal& set "URL=%.:}=!%" & call :dec_url
endlocal& set "URL=%.:}=!%" & exit /b
rem done

'@
[io.file]::WriteAllText("$DIR\OpenWebSearch.cmd", $OpenWebSearch)


# Final Steps 

# Retrieve the Edge_Removal property from the specified registry paths
$userRegPaths = Get-ChildItem -Path 'Registry::HKEY_Users\S-1-5-21*\Volatile*' -ErrorAction SilentlyContinue
$edgeRemovalPath = $userRegPaths | Get-ItemProperty -Name 'Edge_Removal' -ErrorAction SilentlyContinue

# If the Edge_Removal property exists, remove it
if ($edgeRemovalPath) {
    Remove-ItemProperty -Path $edgeRemovalPath.PSPath -Name 'Edge_Removal' -Force -ErrorAction SilentlyContinue
}

# Ensure the explorer process is running
if (-not (Get-Process -Name 'explorer' -ErrorAction SilentlyContinue)) {
    Start-Process 'explorer'
}



