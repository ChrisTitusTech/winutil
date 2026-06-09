function Microwin-GetOscdimg {
    <#
        .DESCRIPTION
        This function will download oscdimg file from github Release folders and put it into env:temp folder

        .EXAMPLE
        Microwin-GetOscdimg
    #>

    try {
        $winget = Get-Command winget -ErrorAction Stop
        $result = & $winget install -e --id Microsoft.OSCDIMG --accept-package-agreements --accept-source-agreements 2>&1
        Write-Win11ISOLog "winget output: $result"
        # Re-scan for oscdimg after install
        $oscdimg = Get-ChildItem "C:\Program Files (x86)\Windows Kits" -Recurse -Filter "oscdimg.exe" -ErrorAction SilentlyContinue |
                    Select-Object -First 1 -ExpandProperty FullName
    } catch {
        Write-Win11ISOLog "winget not available or install failed: $_"
    }

    if (-not $oscdimg) {
        Set-WinUtilProgressBar -Label "" -Percent 0
        Write-Win11ISOLog "oscdimg.exe still not found after install attempt."
        [System.Windows.MessageBox]::Show(
            "oscdimg.exe could not be found or installed automatically.`n`nPlease install it manually:`n  winget install -e --id Microsoft.OSCDIMG`n`nOr install the Windows ADK from:`nhttps://learn.microsoft.com/windows-hardware/get-started/adk-install",
            "oscdimg Not Found", "OK", "Warning")
        return
    }
    Write-Win11ISOLog "oscdimg.exe installed successfully."
    return $true
}
