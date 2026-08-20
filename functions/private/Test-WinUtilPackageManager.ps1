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

    $cmds = @()
    if ($winget) { $cmds += "winget" }
    if ($choco) { $cmds += "choco" }

    foreach ($cmd in $cmds) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            Write-Host "$cmd is not installed" -ForegroundColor Red
            return "not-installed"
        }
        Write-Host "$cmd is installed" -ForegroundColor Green
    }
    return "installed"
}
