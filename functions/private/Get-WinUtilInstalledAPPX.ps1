function Get-WinUtilInstalledAPPX {
    <#

    .SYNOPSIS
        Gets the names of AppX packages installed for all users

    #>

    # AppX module auto-loading can leave PowerShell 7 dependent on a temporary Windows PowerShell
    # compatibility proxy. Run the query in Windows PowerShell 5.1 so it remains available after
    # those temporary proxy files are removed.
    $ps5Command = {
        Get-AppxPackage -AllUsers -ErrorAction Stop | Select-Object -ExpandProperty Name
    }

    $packageOutput = powershell.exe -NoProfile -NonInteractive -Command $ps5Command 2>&1
    if ($LASTEXITCODE -ne 0) {
        $failureDetails = ($packageOutput | Out-String).Trim()
        Write-WinUtilLog -Level "ERROR" -Component "AppX" -Message "Failed to get installed AppX packages: $failureDetails"
        return @()
    }

    return @($packageOutput)
}
