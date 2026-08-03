function Test-WinUtilPackageManager {
    <#
    .SYNOPSIS
        Checks if WinGet and/or Choco are installed.
    .PARAMETER winget
        Check if WinGet is installed.
    .PARAMETER choco
        Check if Chocolatey is installed.
    #>
    Param(
        [System.Management.Automation.SwitchParameter]$winget,
        [System.Management.Automation.SwitchParameter]$choco
    )

    # Handle missing switch - callers rely on the return value
    if (-not $winget -and -not $choco) { return "not-installed" }

    $cmd = if ($winget) { "winget" } else { "choco" }
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Write-Host "$cmd is installed" -ForegroundColor Green
        return "installed"
    } else {
        Write-Host "$cmd is not installed" -ForegroundColor Red
        return "not-installed"
    }
}
