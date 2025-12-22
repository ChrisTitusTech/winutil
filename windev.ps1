<#
.SYNOPSIS
    This Script is used as a target for the https://christitus.com/windev alias.
.DESCRIPTION
    This Script provides a simple way to always start the bleeding edge release even if it's not yet a full release.
.EXAMPLE
    irm https://christitus.com/windev | iex
    OR
    Run in Admin Powershell >  ./windev.ps1
#>

$releases = Invoke-RestMethod 'https://api.github.com/repos/ChrisTitusTech/winutil/releases'

$latestRelease = $releases | Where-Object { $_.prerelease -eq $true } | Select-Object -First 1
$latestTag = $latestRelease.tag_name

if ($latestTag) {
    $url = "https://github.com/ChrisTitusTech/winutil/releases/download/$latestTag/winutil.ps1"
} else {
    $url = "https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1"
}

$script = Invoke-RestMethod $url

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    $powershellcmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    $processCmd = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { $powershellcmd }

    Start-Process $processCmd -ArgumentList "$powershellcmd -ExecutionPolicy Bypass -NoProfile -Command $(Invoke-Expression $script)" -Verb RunAs
} else {
    Invoke-Expression $script
}
