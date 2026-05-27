function Invoke-WinUtilUninstallLauncher {
    <#
    .SYNOPSIS
        Removes the optional WinUtil command launcher.
    .DESCRIPTION
        Deletes the launcher files and removes the launcher bin path
        from the current user's PATH environment variable.
    #>
    $binPath = Join-Path $env:LocalAppData "winutil\bin"

    Write-Host "Uninstalling WinUtil command launcher..."

    try {
        # 1. Remove command launcher files
        $cmdFile = Join-Path $binPath "winutil.cmd"
        $ps1File = Join-Path $binPath "winutil-launcher.ps1"
        $legacyPs1File = Join-Path $binPath "winutil.ps1"

        if (Test-Path $cmdFile) {
            Remove-Item -Path $cmdFile -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $ps1File) {
            Remove-Item -Path $ps1File -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $legacyPs1File) {
            Remove-Item -Path $legacyPs1File -Force -ErrorAction SilentlyContinue
        }

        # Remove directory if empty
        if (Test-Path $binPath) {
            $files = Get-ChildItem -Path $binPath -ErrorAction SilentlyContinue
            if ($null -eq $files -or $files.Count -eq 0) {
                Remove-Item -Path $binPath -Force -ErrorAction SilentlyContinue
            }
        }

        # 2. Remove bin path from User environment PATH
        $registryKey = Get-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -ErrorAction SilentlyContinue
        $currentPath = if ($registryKey) { $registryKey.Path } else { "" }

        $targetPath = $binPath.TrimEnd('\')
        $pathNormalized = $targetPath.Replace('/', '\')

        $paths = $currentPath -split ';'
        $newPaths = @()
        $removed = $false

        foreach ($p in $paths) {
            $pTrimmed = $p.Trim()
            $pNormalized = $pTrimmed.TrimEnd('\').Replace('/', '\')
            if ($pNormalized -ieq $pathNormalized) {
                $removed = $true
            } elseif ($pTrimmed) {
                $newPaths += $pTrimmed
            }
        }

        if ($removed) {
            $newPathString = $newPaths -join ';'
            [System.Environment]::SetEnvironmentVariable('Path', $newPathString, 'User')
            Write-Host "Successfully removed '$targetPath' from User PATH." -ForegroundColor Green
        } else {
            Write-Host "'$targetPath' was not found in User PATH."
        }

        # Update current process PATH session
        $sessionPaths = $env:PATH -split ';'
        $newSessionPaths = @()
        foreach ($sp in $sessionPaths) {
            $spTrimmed = $sp.Trim()
            $spNormalized = $spTrimmed.TrimEnd('\').Replace('/', '\')
            if ($spNormalized -ine $pathNormalized -and $spTrimmed) {
                $newSessionPaths += $spTrimmed
            }
        }
        $env:PATH = $newSessionPaths -join ';'

        # Update launcher registry key to keep state in sync
        $registryPath = "HKCU:\Software\WinUtil"
        if (Test-Path $registryPath) {
            Set-ItemProperty -Path $registryPath -Name "CommandLauncher" -Value 0 -Type DWord
        }

        Write-Host "WinUtil command launcher uninstalled successfully!" -ForegroundColor Green
    } catch {
        Write-Error "Failed to uninstall WinUtil command launcher. Error: $_"
    }
}
