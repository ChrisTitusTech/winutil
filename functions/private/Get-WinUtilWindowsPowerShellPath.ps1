function Get-WinUtilWindowsPowerShellPath {
    <#
    .SYNOPSIS
        Returns the path of Windows PowerShell 5.1, which AppX/DISM operations shell out to
    #>

    # Pinning the full path keeps a lower-trust local process from substituting its own
    # powershell.exe (via PATH or the working directory) into these elevated operations.
    $path = Join-Path $env:windir "System32\WindowsPowerShell\v1.0\powershell.exe"
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Windows PowerShell 5.1 not found at $path"
    }
    return $path
}
