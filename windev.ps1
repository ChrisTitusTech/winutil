<#
.SYNOPSIS
    This script is used as a target for the https://christitus.com/windev alias.
    It queries the latest WinUtil release (no matter if it's a Pre-Release, Draft, or Full Release) and runs it.
.DESCRIPTION
    This script provides a simple way to start the bleeding edge release even if it's not yet a full release.
    This function can be run both with administrator and non-administrator permissions.
    If it is not running as administrator, it will attempt to relaunch itself with administrator permissions.
    The script no longer uses Invoke-Expression for its execution and now relies on Start-Process.
.EXAMPLE
    Run in PowerShell > irm https://christitus.com/windev | iex
    OR
    Run in PowerShell > .\windev.ps1
    OR
    Run in PowerShell > iex "& { $(irm https://christitus.com/windev) } <arguments>"
    OR
    Run in PowerShell > .\windev.ps1 <arguments>
.NOTES
    Below are some usage examples for running the script with arguments:
    Run in PowerShell > iex "& { $(irm https://christitus.com/windev) } -Config 'C:\your\config\file\path\here'"
    OR
    Run in PowerShell > .\windev.ps1 -Config "C:\your\config\file\path\here"
    OR
    Run in PowerShell > iex "& { $(irm https://christitus.com/windev) } -Run -Config 'C:\your\config\file\path\here'"
    OR
    Run in PowerShell > .\windev.ps1 -Run -Config "C:\your\config\file\path\here"
#>

# Speed up file download tasks by suppressing the progress output.
$ProgressPreference = "SilentlyContinue"

# Determine the current elevation status of the running process.
$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Query for the latest WinUtil releases from the source repository.
try {
    # Retrieve the list of WinUtil releases from the source repository.
    $releases = Invoke-RestMethod 'https://api.github.com/repos/ChrisTitusTech/winutil/releases'

    # Filter through WinUtil's releases and select the first stable release tag.
    $stableRelease = $releases | Where-Object { $_.prerelease -eq $false } | Select-Object -First 1

    # Filter through WinUtil's releases and select the first pre-release tag.
    $preRelease = $releases | Where-Object { $_.prerelease -eq $true } | Select-Object -First 1

    # If releases exist, set the release tag based on the first matching release.
    if ($releases -and ($preRelease -or $stableRelease)) {
        $releaseTag = if ($preRelease) { $preRelease.tag_name } elseif ($stableRelease) { $stableRelease.tag_name }
    }

    # If no releases exist, set the release tag to 'latest' and use it as a fallback.
    if (!$releases -or !($preRelease -or $stableRelease)) {
        $releaseTag = "latest"
    }
} catch {
    Write-Host "An error occurred while downloading WinUtil's release information: $_" -ForegroundColor Red
    break
}

# Function to generate the download URL used to download the latest release of WinUtil.
function Get-WinUtilReleaseURL {
    $url = if ($releaseTag -eq "latest") {
        "https://github.com/ChrisTitusTech/winutil/releases/$($releaseTag)/download/winutil.ps1"
    } elseif ($preRelease -or $stableRelease) {
        "https://github.com/ChrisTitusTech/winutil/releases/download/$($releaseTag)/winutil.ps1"
    }

    return $url
}

# Function to check for and download any available updates to WinUtil from the source repository.
function Get-WinUtilUpdates {
    # Define the proxy parameters used to capture the values of $LatestReleaseURL and $WinUtilScriptPath.
    param (
        [Parameter()]
        [string] $ProxyLatestReleaseURL,

        [Parameter()]
        [string] $ProxyWinUtilScriptPath
    )

    # Make a web request to the latest WinUtil release URL and store the raw script's content.
    $RawScriptContent = (Invoke-WebRequest $ProxyLatestReleaseURL -UseBasicParsing).RawContent

    # Extract and store the version numbers for both the remote WinUtil and local WinUtil script.
    $RemoteWinUtilVersion = ([regex]"\bVersion\s*:\s[\d.]+").Match($RawScriptContent).Value -replace ".*:\s", ""
    $LocalWinUtilVersion = ([regex]"\bVersion\s*:\s[\d.]+").Match((Get-Content $ProxyWinUtilScriptPath)).Value -replace ".*:\s", ""

    # Re-download WinUtil from the source repository if it has been upgraded since its last launch time.
    if ([version]$RemoteWinUtilVersion -gt [version]$LocalWinUtilVersion) {
        Write-Host "WinUtil has been upgraded since the last time it was launched. Downloading '$($RemoteWinUtilVersion)'..." -ForegroundColor DarkYellow
        Invoke-RestMethod $ProxyLatestReleaseURL -OutFile $ProxyWinUtilScriptPath
    }

    # Re-download WinUtil from the source repository if it has been downgraded since its last launch time.
    if ([version]$RemoteWinUtilVersion -lt [version]$LocalWinUtilVersion) {
        Write-Host "WinUtil has been downgraded since the last time it was launched. Downloading '$($RemoteWinUtilVersion)'..." -ForegroundColor DarkYellow
        Invoke-RestMethod $ProxyLatestReleaseURL -OutFile $ProxyWinUtilScriptPath
    }

    # Let the user know re-downloading WinUtil is skipped if the downloaded script is already up-to-date.
    if ([version]$RemoteWinUtilVersion -eq [version]$LocalWinUtilVersion) {
        Write-Host "WinUtil is already up-to-date with release: Version '$($RemoteWinUtilVersion)'. Skipped update check." -ForegroundColor Yellow
    }
}

# Function to download the latest release of WinUtil from the source repository.
function Get-LatestWinUtil {
    # Download and save the latest WinUtil release to $env:TEMP\winutil-dev.ps1 on the local disk.
    $LatestReleaseURL = Get-WinUtilReleaseURL
    $WinUtilScriptPath = Join-Path "$env:TEMP" "winutil-dev.ps1"

    if (!(Test-Path $WinUtilScriptPath)) {
        Invoke-RestMethod $LatestReleaseURL -OutFile $WinUtilScriptPath
    } else {
        Get-WinUtilUpdates $LatestReleaseURL $WinUtilScriptPath
    }
}

# Function to start the latest release of WinUtil from the source repository.
function Start-LatestWinUtil {
    param (
        [Parameter(Mandatory = $false)]
        [array]$argsList
    )

    # Create the file path pointing to $env:TEMP\winutil-dev.ps1 on the local disk.
    $WinUtilScriptPath = Join-Path "$env:TEMP" "winutil-dev.ps1"

    # Setup the commands used to launch WinUtil based on what is the preferred console software.
    $powershellCmd = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { "pwsh.exe" } else { "powershell.exe" }
    $processCmd = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { $powershellCmd }

    # Setup the script's launch arguments based on what is used as preferred console software.
    if ($processCmd -ne $powershellCmd) {
        $WinUtilLaunchArguments = "$powershellCmd -ExecutionPolicy Bypass -NoProfile -File `"$WinUtilScriptPath`""
    } else {
        $WinUtilLaunchArguments = "-ExecutionPolicy Bypass -NoProfile -File `"$WinUtilScriptPath`""
    }

    # Append WinUtil's launch arguments from $argsList to the current arguments list if provided.
    if ($argsList) {
        $WinUtilLaunchArguments += " " + $($argsList -join " ")
    }

    # Run the WinUtil script, relaunching it with administrator permissions when they are required.
    if (!$isElevated) {
        Write-Host "WinUtil is not running as administrator. Relaunching with elevated permissions..." -ForegroundColor DarkCyan
        Write-Host "Running the selected WinUtil release: Version '$($releaseTag)' from the source repository." -ForegroundColor Green
        Start-Process $processCmd -ArgumentList $WinUtilLaunchArguments -Wait -Verb RunAs
    } else {
        Write-Host "Running the selected WinUtil release: Version '$($releaseTag)' from the source repository." -ForegroundColor Green  
        Start-Process $processCmd -ArgumentList $WinUtilLaunchArguments -Wait
    }
}

# Download the latest release of WinUtil from the source repository and launch it using Start-LatestWinUtil.
try {
    Get-LatestWinUtil
} catch {
    Write-Host "An error occurred while downloading WinUtil release '$($releaseTag)': $_" -ForegroundColor Red
    break
}

# Start the latest WinUtil release from the source repository; supports WinUtil's arguments if they are provided.
try {
    if ($args) {
        Start-LatestWinUtil $args
    } else {
        Start-LatestWinUtil
    }
} catch {
    Write-Host "An error occurred while launching WinUtil release '$($releaseTag)': $_" -ForegroundColor Red
}
