$scriptName = "remove-trailing-whitespace.ps1"

if (-NOT ((Get-Location).ToString().Split("\")[-1] -eq "winutil")) {
    $border = $("=" * ($scriptName.length + 4))
    $padding = $(" " * ($scriptName.length + 0))
    Write-Host "====================================$border" -Foregroundcolor Red
    Write-Host "-- Tool must be run inside 'winutil'$padding ---" -Foregroundcolor Red
    Write-Host "-- cd 'Path\To\winutil\' -> .\tools\$scriptName ---" -Foregroundcolor Red
    Write-Host "====================================$border" -Foregroundcolor Red
    break
}

# Get all files that we remove trailing whitespace (if any are found) from them
$files = Get-ChildItem -Recurse -Exclude ".\.git\", "LICENSE", "*.png", "*.jpg", "*.jpeg", "*.exe" -Attributes !Directory

# Loop over every file, and do a 'Trim' on it to Trim/Remove Trailing Whitespace
# The general idea was Taken from a StackOverFlow Answer, link to it: https://stackoverflow.com/a/61443973
foreach ($file in $files) {
    (Get-Content "$($file.FullName)").TrimEnd() | Set-Content "$($file.FullName)"
}
