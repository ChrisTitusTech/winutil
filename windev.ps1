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

Invoke-WebRequest "https://github.com/ChrisTitusTech/winutil/archive/refs/heads/main.zip" -OutFile winutil.zip

Expand-Archive .\winutil.zip
Remove-Item .\winutil.zip

Set-Location .\winutil\winutil-main

Invoke-Expression .\Compile.ps1
Invoke-Expression .\winutil.ps1
