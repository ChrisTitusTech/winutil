<#
.SYNOPSIS
    This Script is used as a target for the https://christitus.com/windev alias.
.DESCRIPTION
    This Script provides a simple way to start the bleeding edge release of winutil.
.EXAMPLE
    irm https://christitus.com/windev | iex
    OR
    Run in Admin Powershell >  ./windev.ps1
#>

$releases = Invoke-RestMethod 'https://api.github.com/repos/ChrisTitusTech/winutil/releases'

$latestRelease = $releases | Where-Object { $_.prerelease -eq $true } | Select-Object -First 1
$latestTag = $latestRelease.tag_name

if ($latestTag) {
    Invoke-RestMethod "https://github.com/ChrisTitusTech/winutil/releases/download/$latestTag/winutil.ps1" | Invoke-Expression
} else {
    Invoke-RestMethod "https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1" | Invoke-Expression
}
