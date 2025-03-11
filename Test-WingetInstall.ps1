# Import the function (adjust the path according to your setup)
. "./functions/private/Install-WinUtilWinget.ps1"
. "./functions/private/Test-WinUtilPackageManager.ps1"

# Set up Information stream to be visible
$InformationPreference = "Continue"

Write-Host "Starting Winget installation test..." -ForegroundColor Cyan

try {
    Install-WinUtilWinget
} catch {
    Write-Host "Error occurred during testing: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace:" -ForegroundColor Red
    $_.ScriptStackTrace
}
