function Invoke-WinUtilUninstallPSProfile {
    <#
    .SYNOPSIS
        Restores the PowerShell 7 profile the CTT profile replaced

    .DESCRIPTION
        The profile path has to come from pwsh itself. $PROFILE inside this job is the worker's
        own Windows PowerShell profile, which is not the file the install wrote.
    #>

    $pwshPath = Get-WinUtilPowerShell7Path
    if (-not $pwshPath) {
        throw "PowerShell 7 is not installed, so there is no CTT profile to remove."
    }

    $profilePath = (& $pwshPath -NoProfile -NonInteractive -Command '$PROFILE' | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($profilePath)) {
        throw "Could not determine the PowerShell 7 profile path."
    }
    $profilePath = $profilePath.Trim()
    $backupPath = "$profilePath.bak"

    if (Test-Path $backupPath) {
        Move-Item -Path $backupPath -Destination $profilePath -Force
        Write-WinUtilLog -Component "Feature" -Message "Restored the profile that was in place before: $profilePath"
        return
    }

    if (Test-Path $profilePath) {
        Remove-Item -Path $profilePath -Force
        Write-WinUtilLog -Component "Feature" -Message "Removed the CTT PowerShell profile: $profilePath"
        return
    }

    Write-WinUtilLog -Level "WARN" -Component "Feature" -Message "No PowerShell 7 profile found at $profilePath, nothing to remove."
}
