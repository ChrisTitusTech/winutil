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
#>

# Speed up download-related tasks by suppressing the output of Write-Progress.
$ProgressPreference = "SilentlyContinue"

# Determine whether or not the active process is currently running as administrator.
$ProcessIsElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Function to get the latest stable or pre-release tag from the repository's releases page.
function Get-WinUtilReleaseTag {
    # Retrieve the list of released versions from the repository's releases page.
    try {
        $ReleasesList = Invoke-RestMethod 'https://api.github.com/repos/ChrisTitusTech/winutil/releases'
    } catch {
        Write-Host "Error downloading WinUtil's releases list: $_" -ForegroundColor Red
        break
    }

    # Filter through the released versions and select the first matching stable or pre-release version.
    $StableRelease = $ReleasesList | Where-Object { -not $_.prerelease } | Select-Object -First 1
    $PreRelease = $ReleasesList | Where-Object { $_.prerelease } | Select-Object -First 1

    # Set the release tag based on the available releases; if no release tag is found use the 'latest' tag.
    $ReleaseTag = if ($PreRelease) {
        $PreRelease.tag_name
    } elseif ($StableRelease) {
        $StableRelease.tag_name
    } else {
        "latest"
    }

    # Return the release tag to facilitate the usage of the version number within other parts of the script.
    return $ReleaseTag
}

# Get the latest stable or pre-release tag; falling back to the 'latest' release tag if no releases are found.
$WinUtilReleaseTag = Get-WinUtilReleaseTag

# Function to generate the URL used to download the latest release of WinUtil from the releases page.
function Get-WinUtilReleaseURL {
    $WinUtilDownloadURL = if ($WinUtilReleaseTag -eq "latest") {
        "https://github.com/ChrisTitusTech/winutil/releases/$($WinUtilReleaseTag)/download/winutil.ps1"
    } else {
        "https://github.com/ChrisTitusTech/winutil/releases/download/$($WinUtilReleaseTag)/winutil.ps1"
    }

    return $WinUtilDownloadURL
}

# Get the URL used to download the latest release of WinUtil from the releases page.
$WinUtilReleaseURL = Get-WinUtilReleaseURL

# Create the file path that the latest WinUtil release will be downloaded to on the local disk.
$WinUtilScriptPath = Join-Path "$env:TEMP" "winutil.ps1"

# Function to download the latest release of WinUtil from the releases page to the local disk.
function Get-LatestWinUtil {
    if (!(Test-Path $WinUtilScriptPath)) {
        Write-Host "WinUtil is not found. Downloading WinUtil '$($WinUtilReleaseTag)'..." -ForegroundColor DarkYellow
        Invoke-RestMethod $WinUtilReleaseURL -OutFile $WinUtilScriptPath
    }
}

# Function to check for any version changes to WinUtil, re-downloading the script if it has been upgraded/downgraded.
function Get-WinUtilUpdates {
    # Make a web request to the latest WinUtil release URL and store the script's raw code for processing.
    $RawWinUtilScript = (Invoke-WebRequest $WinUtilReleaseURL -UseBasicParsing).RawContent

    # Create the regular expression pattern used to extract the script's version number from the script's raw content.
    $VersionExtractionRegEx = "(\bVersion\s*:\s)([\d.]+)"

    # Match the entire 'Version:' header and extract the script's version number directly using RegEx capture groups.
    $RemoteWinUtilVersion = (([regex]($VersionExtractionRegEx)).Match($RawWinUtilScript).Groups[2].Value)
    $LocalWinUtilVersion = (([regex]($VersionExtractionRegEx)).Match((Get-Content $WinUtilScriptPath)).Groups[2].Value)

    # Check if WinUtil needs an update and either download a fresh copy or notify the user its already up-to-date.
    if ([version]$RemoteWinUtilVersion -ne [version]$LocalWinUtilVersion) {
        Write-Host "WinUtil is out-of-date. Downloading WinUtil '$($RemoteWinUtilVersion)'..." -ForegroundColor DarkYellow
        Invoke-RestMethod $WinUtilReleaseURL -OutFile $WinUtilScriptPath
    } else {
        Write-Host "WinUtil is already up-to-date. Skipped update checking." -ForegroundColor Yellow
    }
}

# Function to start the latest release of WinUtil that was previously downloaded and saved to '$env:TEMP\winutil.ps1'.
function Start-LatestWinUtil {
    param (
        [Parameter(Mandatory = $false)]
        [array]$WinUtilArgumentsList
    )

    # Setup the commands used to launch WinUtil using Windows Terminal or Windows PowerShell/PowerShell Core.
    $PowerShellCommand = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { "pwsh.exe" } else { "powershell.exe" }
    $ProcessCommand = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { $PowerShellCommand }

    # Setup the script's launch arguments based on the presence of Windows Terminal or Windows PowerShell/PowerShell Core:
    # 1. Windows Terminal needs the name of the process to start ($PowerShellCommand) in addition to the launch arguments.
    # 2. Windows PowerShell and PowerShell Core can receive and use the launch arguments as is without extra modification.
    $WinUtilLaunchArguments = "-ExecutionPolicy Bypass -NoProfile -File `"$WinUtilScriptPath`""
    if ($ProcessCommand -ne $PowerShellCommand) {
        $WinUtilLaunchArguments = "$PowerShellCommand $WinUtilLaunchArguments"
    }

    # If WinUtil's launch arguments are provided, append them to the end of the list of current launch arguments.
    if ($WinUtilArgumentsList) {
        $WinUtilLaunchArguments += " " + $($WinUtilArgumentsList -join " ")
    }

    # If the WinUtil script is not running as administrator, relaunch the script with administrator permissions.
    if (!$ProcessIsElevated) {
        Write-Host "WinUtil is not running as administrator. Relaunching..." -ForegroundColor DarkCyan
        Write-Host "Running the selected WinUtil release: Version '$($WinUtilReleaseTag)'." -ForegroundColor Green
        Start-Process $ProcessCommand -ArgumentList $WinUtilLaunchArguments -Wait -Verb RunAs
    } else {
        Write-Host "Running the selected WinUtil release: Version '$($WinUtilReleaseTag)'." -ForegroundColor Green
        Start-Process $ProcessCommand -ArgumentList $WinUtilLaunchArguments -Wait
    }
}

# If WinUtil has not already been downloaded, attempt to download it and save it to '$env:TEMP\winutil.ps1'.
try {
    Get-LatestWinUtil
} catch {
    Write-Host "Error downloading WinUtil '$($WinUtilReleaseTag)': $_" -ForegroundColor Red
    break
}

# Attempt to check for WinUtil updates, if a version is released or removed this will re-download WinUtil.
try {
    Get-WinUtilUpdates
} catch {
    Write-Host "Error updating WinUtil '$($WinUtilReleaseTag)': $_" -ForegroundColor Red
    break
}

# Attempt to start the latest release of WinUtil saved to the local disk; also supports WinUtil's arguments.
try {
    if ($args) {
        Start-LatestWinUtil $args
    } else {
        Start-LatestWinUtil
    }
} catch {
    Write-Host "Error launching WinUtil '$($WinUtilReleaseTag)': $_" -ForegroundColor Red
}
