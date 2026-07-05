function Test-WinUtilTrustedInstallerPath {
    <#
    .SYNOPSIS
        Checks whether the TrustedInstaller service ImagePath looks safe.

    .DESCRIPTION
        Windows Update depends on the Windows Modules Installer service. If that
        service's ImagePath is hijacked to launch a shell, PowerShell, script host,
        or temp/AppData payload, Windows Update repair steps can fail or trigger
        antivirus blocks. This function is intentionally read-only; protected
        TrustedInstaller service registry values should not be rewritten here.

    .OUTPUTS
        Boolean. True when the path is expected or could not be inspected; false
        when a suspicious ImagePath is detected.
    #>

    $expectedPath = "$env:SystemRoot\servicing\TrustedInstaller.exe"
    $expectedRegistryPath = "%SystemRoot%\servicing\TrustedInstaller.exe"
    $suspiciousPattern = "(?i)(encodedcommand|powershell(\.exe)?|cmd\.exe|wscript(\.exe)?|cscript(\.exe)?|mshta(\.exe)?|\bAppData\b|\bTemp\b)"

    try {
        $trustedInstaller = Get-CimInstance -ClassName Win32_Service -Filter "Name='TrustedInstaller'" -ErrorAction Stop
    } catch {
        Write-Warning "Unable to inspect TrustedInstaller service path: $($_.Exception.Message)"
        Write-WinUtilLog -Level "WARN" -Component "Updates" -Message "Unable to inspect TrustedInstaller service path: $($_.Exception.Message)"
        return $true
    }

    if ($null -eq $trustedInstaller) {
        Write-Warning "TrustedInstaller service was not found. Windows Update repair may not complete successfully."
        Write-WinUtilLog -Level "WARN" -Component "Updates" -Message "TrustedInstaller service was not found during Windows Update repair preflight."
        return $true
    }

    $pathName = [string]$trustedInstaller.PathName
    $expandedPath = [Environment]::ExpandEnvironmentVariables($pathName).Trim('"')
    $normalizedExpectedPath = [Environment]::ExpandEnvironmentVariables($expectedRegistryPath)

    if ($expandedPath -ieq $expectedPath -or $expandedPath -ieq $normalizedExpectedPath) {
        return $true
    }

    if ($pathName -match $suspiciousPattern) {
        $message = "TrustedInstaller service ImagePath looks suspicious: '$pathName'. Expected '$expectedRegistryPath'. Windows Update repair may not succeed until this is repaired offline."
        Write-Warning $message
        Write-WinUtilLog -Level "WARN" -Component "Updates" -Message $message
        return $false
    }

    Write-WinUtilLog -Level "WARN" -Component "Updates" -Message "TrustedInstaller service ImagePath differs from expected value: '$pathName'. Expected '$expectedRegistryPath'."
    return $true
}
