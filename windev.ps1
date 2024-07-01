<#
.SYNOPSIS
    This Script is used as a target for the https://christitus.com/windev alias.
    It queries the latest winget release (no matter if Pre-Release, Draft or Full Release) and invokes It
.DESCRIPTION
    This Script provides a simple way to always start the bleeding edge release even if it's not yet a full release.
    This function should be run with administrative privileges.
    Because this way of recursively invoking scripts via Invoke-Expression it might very well happen that AV Programs flag this because it's a common way of mulitstage exploits to run
.EXAMPLE
    irm https://christitus.com/windev | iex
    OR
    Run in Admin Powershell >  ./windev.ps1
#>

# Function to fetch the latest release tag from the GitHub API
function Get-LatestRelease {
    try {
        $releases = Invoke-RestMethod -Uri 'https://api.github.com/repos/ChrisTitusTech/winutil/releases'
        $latestRelease = $releases | Where-Object {$_.prerelease -eq $true} | Select-Object -First 1
        return $latestRelease.tag_name
    } catch {
        Write-Host "Error fetching release data: $_" -ForegroundColor Red
        return $latestRelease.tag_name
    }
}

# Function to redirect to the latest pre-release version
function RedirectToLatestPreRelease {
    $latestRelease = Get-LatestRelease
    if ($latestRelease) {
        $url = "https://raw.githubusercontent.com/ChrisTitusTech/winutil/$latestRelease/winutil.ps1"
    } else {
        Write-Host 'Unable to determine latest pre-release version.' -ForegroundColor Red
        Write-Host "Using latest Full Release"
        $url = "https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1"
    }
    Invoke-RestMethod $url | Invoke-Expression
}

# Call the redirect function

RedirectToLatestPreRelease
