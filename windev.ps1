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

$latestTag = (Invoke-RestMethod https://api.github.com/repos/ChrisTitusTech/winutil/tags).Name | Select-Object -First 1
Invoke-RestMethod -Uri https://github.com/ChrisTitusTech/winutil/releases/download/$latestTag/winutil.ps1 | Invoke-Expression
