# Runs the pre-release version of winutil
param (
    [string]$Config,
    [ValidateSet("Standard", "Minimal", "Advanced")]
    [string]$Preset
)

$latestTag = (Invoke-RestMethod https://api.github.com/repos/ChrisTitusTech/winutil/tags).Name | Select-Object -First 1
$scriptString = Invoke-RestMethod -Uri https://github.com/ChrisTitusTech/winutil/releases/download/$latestTag/winutil.ps1
$env:WINUTIL_DEV_TAG = $latestTag

# turn the string into a script block, forward params and execute; @args dont work
$scriptBlock = [scriptblock]::Create($scriptString)
& $scriptBlock @PSBoundParameters