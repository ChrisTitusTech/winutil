function Invoke-WPFFixesDesktopIconFixer {

    <#

    .SYNOPSIS
        Rebuilds Windows desktop icon and thumbnail caches.

    .DESCRIPTION
        Stops Explorer, clears icon/thumbnail cache databases, and restarts Explorer.

    #>
    try {
        Set-WinUtilTaskbaritem -state "Indeterminate" -overlay "logo"
        Write-Host "==> Starting Desktop Icon Fix"

        # Ensure Explorer releases cache file locks before cleanup.
        Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2

        $cachePatterns = @(
            "$env:LOCALAPPDATA\IconCache.db",
            "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db",
            "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db"
        )

        foreach ($pattern in $cachePatterns) {
            Remove-Item -Path $pattern -Force -ErrorAction SilentlyContinue
        }

        Start-Process -FilePath "explorer.exe"
        Write-Host "==> Desktop icon cache rebuilt successfully"
    } catch {
        Write-Error "Failed to rebuild desktop icon cache: $_"
        Set-WinUtilTaskbaritem -state "Error" -overlay "warning"
    } finally {
        Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"
        Write-Host "==> Finished Desktop Icon Fix"
    }
}
