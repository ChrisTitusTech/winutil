function Install-WinUtilWinGetClient {
    <#
        .SYNOPSIS
            Makes the Microsoft.WinGet.Client module available, and reports whether it is

        .DESCRIPTION
            The winget command line hides its progress bar as soon as its output is redirected,
            so a caller can never report how far along an install is. The module reports
            progress and a structured result instead, which is what lets WinUtil show real
            percentages rather than a bar that jumps from nothing to done.

            The answer is cached for the session. Installing the module reaches the PowerShell
            Gallery and takes some seconds, so a machine that cannot get it falls back to the
            command line rather than paying that cost on every call.
    #>

    if ($null -ne $sync.WinGetClientReady) {
        return $sync.WinGetClientReady
    }

    if (Get-Module -Name Microsoft.WinGet.Client) {
        $sync.WinGetClientReady = $true
        return $true
    }

    try {
        if (-not (Get-Module -ListAvailable -Name Microsoft.WinGet.Client)) {
            Write-WinUtilLog -Component "Package" -Message "Installing the Microsoft.WinGet.Client module."
            Write-WinUtilJobProgress -Status "Preparing the WinGet client" -State "Indeterminate"

            if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
                Install-PackageProvider -Name NuGet -Force -Scope CurrentUser -ErrorAction Stop | Out-Null
            }
            Install-Module -Name Microsoft.WinGet.Client -Force -Scope CurrentUser -Repository PSGallery -ErrorAction Stop
        }

        Import-Module Microsoft.WinGet.Client -ErrorAction Stop
        Write-WinUtilLog -Component "Package" -Message "WinGet client module ready: $((Get-Module Microsoft.WinGet.Client).Version)"
        $sync.WinGetClientReady = $true
    } catch {
        Write-WinUtilLog -Level "WARN" -Component "Package" -Message "WinGet client module unavailable, falling back to the winget command line: $($_.Exception.Message)"
        $sync.WinGetClientReady = $false
    }

    return $sync.WinGetClientReady
}
