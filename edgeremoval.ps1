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
@echo off
@title OpenWebSearch Redux

:: Minimize prompt
for /f %%E in ('"prompt $E$S & for %%e in (1) do rem"') do echo;%%E[2t >nul 2>&1

:: Get default browser from registry
call :get_registry_value "HKCU\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice" ProgID DefaultBrowser
if not defined DefaultBrowser (
    echo Error: Failed to get default browser from registry.
    pause
    exit /b
)
if /i "%DefaultBrowser%" equ "MSEdgeHTM" (
    echo Error: Default browser is set to Edge! Change it or remove OpenWebSearch script.
    pause
    exit /b
)

:: Get browser command line
call :get_registry_value "HKCR\%DefaultBrowser%\shell\open\command" "" BrowserCommand
if not defined BrowserCommand (
    echo Error: Failed to get browser command from registry.
    pause
    exit /b
)
set Browser=& for %%i in (%BrowserCommand%) do if not defined Browser set "Browser=%%~i"

:: Set fallback for Edge
call :get_registry_value "HKCR\MSEdgeMHT\shell\open\command" "" FallBack
set EdgeCommand=& for %%i in (%FallBack%) do if not defined EdgeCommand set "EdgeCommand=%%~i"

:: Parse command line arguments and check for redirect or noop conditions
set "URI=" & set "URL=" & set "NOOP=" & set "PassThrough=%EdgeCommand:msedge=edge%"
set "CommandLineArgs=%CMDCMDLINE:"=``% "
call :parse_arguments

if defined NOOP (
    if not exist "%PassThrough%" (
        echo Error: PassThrough path doesn't exist.
        pause
        exit /b
    )
    start "" "%PassThrough%" %ParsedArgs%
    exit /b
)

:: Decode URL
call :decode_url
if not defined URL (
    echo Error: Failed to decode URL.
    pause
    exit /b
)

:: Open URL in default browser
start "" "%Browser%" "%URL%"
exit

:: Functions

:get_registry_value
setlocal
    set regQuery=reg query "%~1" /v %2 /z /se "," /f /e
    if "%~2" equ "" set regQuery=reg query "%~1" /ve /z /se "," /f /e
    for /f "skip=2 tokens=* delims=" %%V in ('%regQuery% 2^>nul') do set "result=%%V"
    if defined result (set "result=%result:*)    =%") else (set "%~3=")
    endlocal & set "%~3=%result%"
exit /b

:decode_url
    :: Brute URL percent decoding
    setlocal enabledelayedexpansion
    set "decoded=%URL:!=}%"
    call :brute_decode
    endlocal & set "URL=%decoded%"
exit /b

:parse_arguments
    :: Remove specific substrings from arguments
    set "CommandLineArgs=%CommandLineArgs:*ie_to_edge_stub.exe`` =%"
    set "CommandLineArgs=%CommandLineArgs:*ie_to_edge_stub.exe =%"
    set "CommandLineArgs=%CommandLineArgs:*msedge.exe`` =%"
    set "CommandLineArgs=%CommandLineArgs:*msedge.exe =%"

    :: Remove any trailing spaces
    if "%CommandLineArgs:~-1%"==" " set "CommandLineArgs=%CommandLineArgs:~0,-1%"

    :: Check if arguments are a redirect or URL
    set "RedirectArg=%CommandLineArgs:microsoft-edge=%"
    set "UrlArg=%CommandLineArgs:http=%"
    set "ParsedArgs=%CommandLineArgs:``="%"

    :: Set NOOP flag if no changes to arguments
    if "%CommandLineArgs%" equ "%RedirectArg%" (set NOOP=1) else if "%CommandLineArgs%" equ "%UrlArg%" (set NOOP=1)

    :: Extract URL if present
    if not defined NOOP (
        set "URL=%CommandLineArgs:*microsoft-edge=%"
        set "URL=http%URL:*http=%"
        if "%URL:~-2%"=="``" set "URL=%URL:~0,-2%"
    )
exit /b


:brute_decode
    :: Brute force URL percent decoding

    set "decoded=%decoded:%%20= %"
    set "decoded=%decoded:%%21=!!"
    set "decoded=%decoded:%%22="%""
    set "decoded=%decoded:%%23=#%"
    set "decoded=%decoded:%%24=$%"
    set "decoded=%decoded:%%25=%%%"
    set "decoded=%decoded:%%26=&%"
    set "decoded=%decoded:%%27='%"
    set "decoded=%decoded:%%28=(%"
    set "decoded=%decoded:%%29=)%" 
    set "decoded=%decoded:%%2A=*%"
    set "decoded=%decoded:%%2B=+%"
    set "decoded=%decoded:%%2C=,%"
    set "decoded=%decoded:%%2D=-%"
    set "decoded=%decoded:%%2E=.%"
    set "decoded=%decoded:%%2F=/%"
    :: ... Continue for other encodings ...

    :: Correct any double percentage signs
    set "decoded=%decoded:%%%%=%"

exit /b



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



