function Get-WinUtilWindowsPowerShellPath {
    <#
    .SYNOPSIS
        Returns the path of Windows PowerShell 5.1, which AppX/DISM operations shell out to
    #>

    # Pinning the full path keeps a lower-trust local process from substituting its own
    # powershell.exe (via PATH or the working directory) into these elevated operations.
    # [Environment]::SystemDirectory comes from the OS, not from the (attacker-influenceable)
    # WINDIR environment variable inherited by the UAC child.
    $path = Join-Path ([Environment]::SystemDirectory) "WindowsPowerShell\v1.0\powershell.exe"
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Windows PowerShell 5.1 not found at $path"
    }
    return $path
}
