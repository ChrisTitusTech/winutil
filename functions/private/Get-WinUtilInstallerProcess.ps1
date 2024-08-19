function Get-WinUtilInstallerProcess {
    <#

    .SYNOPSIS
        Checks if the given process is running

    .PARAMETER Process
        The process to check

    .OUTPUTS
        Boolean - True if the process is running

    #>

    param($Process)

    if ($Null -eq $Process) {
        return $false
    }
    if (Get-Process -Id $Process.Id -ErrorAction SilentlyContinue) {
        return $true
    }
    return $false
}
