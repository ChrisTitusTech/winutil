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
$ProcessIsElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Function to query the source repository for the latest matching release tag.
function Get-WinUtilReleaseTag {
    # Retrieve the list of WinUtil's releases from the source repository.
    try {
        $ReleasesList = Invoke-RestMethod 'https://api.github.com/repos/ChrisTitusTech/winutil/releases'
    } catch {
        Write-Host "An error occurred while downloading WinUtil's releases list: $_" -ForegroundColor Red
        break
    }

    # Filter through WinUtil's releases and select the first stable release tag.
    $StableRelease = $ReleasesList | Where-Object { $_.prerelease -eq $false } | Select-Object -First 1

    # Filter through WinUtil's releases and select the first pre-release tag.
    $PreRelease = $ReleasesList | Where-Object { $_.prerelease -eq $true } | Select-Object -First 1

    # If a compatible release exists, set the release tag based on the first matching release.
    if ($ReleasesList -and ($PreRelease -or $StableRelease)) {
        $ReleaseTag = if ($PreRelease) { $PreRelease.tag_name } elseif ($StableRelease) { $StableRelease.tag_name }
    }

    # If no compatible releases exist, set the release tag to 'latest' and use it as a fallback.
    if (!$ReleasesList -or !($PreRelease -or $StableRelease)) {
        $ReleaseTag = "latest"
    }

    # Return the $ReleaseTag variable to allow the usage of the returned version within other functions.
    return $ReleaseTag
}

# Function to generate the download URL used to download the latest release of WinUtil.
function Get-WinUtilReleaseURL {
    $WinUtilDownloadURL = if ($ReleaseTag -eq "latest") {
        "https://github.com/ChrisTitusTech/winutil/releases/$($ReleaseTag)/download/winutil.ps1"
    } elseif ($PreRelease -or $StableRelease) {
        "https://github.com/ChrisTitusTech/winutil/releases/download/$($ReleaseTag)/winutil.ps1"
    }

    return $WinUtilDownloadURL
}

# Get the URL to download the latest version of WinUtil from the source repository.
$WinUtilReleaseURL = Get-WinUtilReleaseURL

# Create the file path pointing to $env:TEMP\winutil-dev.ps1 on the local disk.
$WinUtilScriptPath = Join-Path "$env:TEMP" "winutil-dev.ps1"

# Function to download the latest release of WinUtil from the source repository.
function Get-LatestWinUtil {
    # Download and save the latest WinUtil release to the user's $env:TEMP directory.
    if (!(Test-Path $WinUtilScriptPath)) {
        Invoke-RestMethod $WinUtilReleaseURL -OutFile $WinUtilScriptPath
    }
}

# Function to download any available updates to WinUtil from the source repository.
function Get-WinUtilUpdates {
    # Make a web request to the latest WinUtil release URL and store the raw script's content.
    $RawWinUtilScript = (Invoke-WebRequest $WinUtilReleaseURL -UseBasicParsing).RawContent

    # Extract and store the version numbers for both the remote WinUtil and local WinUtil script.
    $RemoteWinUtilVersion = ([regex]"\bVersion\s*:\s[\d.]+").Match($RawWinUtilScript).Value -replace ".*:\s", ""
    $LocalWinUtilVersion = ([regex]"\bVersion\s*:\s[\d.]+").Match((Get-Content $WinUtilScriptPath)).Value -replace ".*:\s", ""

    # Re-download WinUtil from the source repository if it has been upgraded since its last launch time.
    if ([version]$RemoteWinUtilVersion -gt [version]$LocalWinUtilVersion) {
        Write-Host "WinUtil has been upgraded since the last time it was launched. Downloading '$($RemoteWinUtilVersion)'..." -ForegroundColor DarkYellow
        Invoke-RestMethod $WinUtilReleaseURL -OutFile $WinUtilScriptPath
    }

    # Re-download WinUtil from the source repository if it has been downgraded since its last launch time.
    if ([version]$RemoteWinUtilVersion -lt [version]$LocalWinUtilVersion) {
        Write-Host "WinUtil has been downgraded since the last time it was launched. Downloading '$($RemoteWinUtilVersion)'..." -ForegroundColor DarkYellow
        Invoke-RestMethod $WinUtilReleaseURL -OutFile $WinUtilScriptPath
    }

    # Let the user know re-downloading WinUtil is skipped if the downloaded script is already up-to-date.
    if ([version]$RemoteWinUtilVersion -eq [version]$LocalWinUtilVersion) {
        Write-Host "WinUtil is already up-to-date with release: Version '$($RemoteWinUtilVersion)'. Skipped update check." -ForegroundColor Yellow
    }
}

# Function to start the latest release of WinUtil from the source repository.
function Start-LatestWinUtil {
    param (
        [Parameter(Mandatory = $false)]
        [array]$WinUtilArguments
    )

    # Setup the commands used to launch WinUtil based on the preferred console host.
    $PowerShellCommand = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { "pwsh.exe" } else { "powershell.exe" }
    $ProcessCommand = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { $PowerShellCommand }

    # Setup the script's launch arguments based on the preferred console host.
    if ($ProcessCommand -ne $PowerShellCommand) {
        $WinUtilArgumentsList = "$PowerShellCommand -ExecutionPolicy Bypass -NoProfile -File `"$WinUtilScriptPath`""
    } else {
        $WinUtilArgumentsList = "-ExecutionPolicy Bypass -NoProfile -File `"$WinUtilScriptPath`""
    }

    # Append WinUtil's launch arguments from $WinUtilArguments to the current arguments list if provided.
    if ($WinUtilArguments) {
        $WinUtilArgumentsList += " " + $($WinUtilArguments -join " ")
    }

    # Run the WinUtil script, relaunching it with administrator permissions when they are required.
    if (!$ProcessIsElevated) {
        Write-Host "WinUtil is not running as administrator. Relaunching with elevated permissions..." -ForegroundColor DarkCyan
        Write-Host "Running the selected WinUtil release: Version '$($ReleaseTag)' from the source repository." -ForegroundColor Green
        Start-Process $ProcessCommand -ArgumentList $WinUtilArgumentsList -Wait -Verb RunAs
    } else {
        Write-Host "Running the selected WinUtil release: Version '$($ReleaseTag)' from the source repository." -ForegroundColor Green
        Start-Process $ProcessCommand -ArgumentList $WinUtilArgumentsList -Wait
    }
}

# Download the latest release of WinUtil if not already downloaded from the source repository.
try {
    Get-LatestWinUtil
} catch {
    Write-Host "An error occurred while downloading WinUtil release '$($ReleaseTag)': $_" -ForegroundColor Red
    break
}

# Check for and download any newly released version of WinUtil from the source repository.
# This same behavior will also apply to downgrades should any new releases get rolled back.
try {
    Get-WinUtilUpdates
} catch {
    Write-Host "An error occurred while upgrading/downgrading WinUtil release '$($ReleaseTag)': $_" -ForegroundColor Red
    break
}

# Start the latest WinUtil release from the source repository; supports WinUtil's arguments if provided.
try {
    if ($args) {
        Start-LatestWinUtil $args
    } else {
        Start-LatestWinUtil
    }
} catch {
    Write-Host "An error occurred while launching WinUtil release '$($ReleaseTag)': $_" -ForegroundColor Red
}
