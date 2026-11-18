function Set-WinUtilClassicContextMenu {
    param([switch]$Undo)

    $clsidPath = 'HKCU:\Software\Classes\CLSID'
    $legacyPath = "$clsidPath\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
    $workaroundPath = "$clsidPath\{51668040-5e31-4023-bbe3-149163bd80f1}"
    $serverPath = "$workaroundPath\InprocServer32"
    $markerName = 'WinUtilClassicContextMenu'

    $workaroundKey = $null
    try {
        $workaroundKey = Get-Item -LiteralPath $workaroundPath -ErrorAction Stop
    } catch [System.Management.Automation.ItemNotFoundException] {
        # The newer registration is optional.
    }
    $marker = if ($null -ne $workaroundKey) { $workaroundKey.GetValue($markerName) }
    $ownsWorkaround = $marker -is [int] -and $marker -eq 1

    if ($Undo) {
        # Older WinUtil builds applied the original override without an ownership marker.
        try {
            Remove-Item -LiteralPath $legacyPath -Recurse -Force -ErrorAction Stop
        } catch [System.Management.Automation.ItemNotFoundException] {
            # The original override is already absent.
        }

        if ($ownsWorkaround) {
            try {
                if ($workaroundKey.ValueCount -gt 1 -or
                    ($workaroundKey.GetSubKeyNames() | Where-Object { $_ -ne 'InprocServer32' })) {
                    throw "The classic context menu registry key '$workaroundPath' has additional entries and was left intact."
                }
                if ($workaroundKey.SubKeyCount -gt 0) {
                    $serverKey = Get-Item -LiteralPath $serverPath -ErrorAction Stop
                    if ($serverKey.SubKeyCount -gt 0 -or $serverKey.ValueCount -gt 1 -or
                        ($serverKey.ValueCount -eq 1 -and
                            ($serverKey.GetValueNames() -notcontains '' -or
                             $serverKey.GetValueKind('') -ne [Microsoft.Win32.RegistryValueKind]::String -or
                             $serverKey.GetValue('') -ne ''))) {
                        throw "The classic context menu registry key '$serverPath' has been changed and was left intact."
                    }
                }
                Remove-Item -LiteralPath $workaroundPath -Recurse -Force -ErrorAction Stop
            } catch [System.Management.Automation.ItemNotFoundException] {
                # The key disappeared before cleanup completed.
            }
        }
    } else {
        New-Item -Path $legacyPath -Name InprocServer32 -Value '' -Force -ErrorAction Stop | Out-Null

        if ($null -eq $workaroundKey) {
            # The first override ensures the CLSID parent exists, so -Force is unnecessary.
            $workaroundKey = New-Item -Path $workaroundPath -ErrorAction Stop
            try {
                New-ItemProperty -LiteralPath $workaroundPath -Name $markerName -Value 1 -PropertyType DWord -ErrorAction Stop | Out-Null
            } catch {
                if ($workaroundKey.ValueCount -eq 0 -and $workaroundKey.SubKeyCount -eq 0) {
                    Remove-Item -LiteralPath $workaroundPath -ErrorAction Stop
                }
                throw
            }
            $ownsWorkaround = $true
        }
        if ($ownsWorkaround -and -not (Test-Path -LiteralPath $serverPath -ErrorAction Stop)) {
            New-Item -Path $serverPath -Value '' -ErrorAction Stop | Out-Null
        } elseif ($ownsWorkaround) {
            $serverKey = Get-Item -LiteralPath $serverPath -ErrorAction Stop
            if ($serverKey.ValueCount -eq 0 -and $serverKey.SubKeyCount -eq 0) {
                # Key creation can succeed before assigning its default value fails.
                Set-Item -LiteralPath $serverPath -Value '' -Force -ErrorAction Stop
            }
        }
    }

    $sessionId = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
    Get-Process -Name explorer -ErrorAction SilentlyContinue |
        Where-Object { $_.SessionId -eq $sessionId } |
        ForEach-Object { Stop-Process -Id $_.Id -ErrorAction SilentlyContinue }
}
