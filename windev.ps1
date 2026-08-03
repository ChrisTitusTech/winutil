# Runs the pre-release version of winutil

$latestTag = (Invoke-RestMethod https://api.github.com/repos/ChrisTitusTech/winutil/tags).Name | Select-Object -First 1
$uri = "https://github.com/ChrisTitusTech/winutil/releases/download/$latestTag/winutil.ps1"
$scriptPath = Join-Path $env:TEMP "winutil-$latestTag.ps1"

Invoke-WebRequest -Uri $uri -OutFile $scriptPath -UseBasicParsing -ErrorAction Stop

$powerShellCmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
& $powerShellCmd -ExecutionPolicy Bypass -NoProfile -File $scriptPath
