# Runs the pre-release version of winutil

$windev = $true

$latestTag = (Invoke-RestMethod https://api.github.com/repos/ChrisTitusTech/winutil/tags).Name | Select-Object -First 1
"& ([ScriptBlock]::Create((irm https://github.com/ChrisTitusTech/winutil/releases/download/$latestTag/winutil.ps1))) $args"
