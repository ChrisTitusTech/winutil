# Runs the pre-release version of winutil

$latestTag = (Invoke-RestMethod https://api.github.com/repos/ChrisTitusTech/winutil/tags).Name | Select-Object -First 1
$script = Invoke-RestMethod -Uri https://github.com/ChrisTitusTech/winutil/releases/download/$latestTag/winutil.ps1
Invoke-Command -ScriptBlock ([scriptblock]::Create($script)) -ErrorAction Stop
