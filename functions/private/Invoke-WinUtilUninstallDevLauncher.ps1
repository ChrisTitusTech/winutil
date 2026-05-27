function Invoke-WinUtilUninstallDevLauncher {
    <#
    .SYNOPSIS
        Removes the optional WinUtil development command launcher.
    .DESCRIPTION
        Deletes the dev launcher files and removes the launcher bin path
        from the current user's PATH environment variable if the regular launcher is also not installed.
    #>
    $binPath = Join-Path $env:LocalAppData "winutil\bin"

    Write-Host "Uninstalling WinUtil Dev command launcher..."

    try {
        # 1. Remove command launcher files
        $cmdFile = Join-Path $binPath "winutil-dev.cmd"
        $ps1File = Join-Path $binPath "winutil-dev-launcher.ps1"
        $legacyPs1File = Join-Path $binPath "winutil-dev.ps1"

        if (Test-Path $cmdFile) {
            Remove-Item -Path $cmdFile -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $ps1File) {
            Remove-Item -Path $ps1File -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $legacyPs1File) {
            Remove-Item -Path $legacyPs1File -Force -ErrorAction SilentlyContinue
        }

        # Check if the regular launcher files are still present in the directory
        $regularCmd = Join-Path $binPath "winutil.cmd"
        $regularPs1 = Join-Path $binPath "winutil-launcher.ps1"
        $hasRegular = (Test-Path $regularCmd) -or (Test-Path $regularPs1)

        # 2. Only remove directory and PATH if regular launcher is not installed
        if (-not $hasRegular) {
            # Remove directory if empty
            if (Test-Path $binPath) {
                $files = Get-ChildItem -Path $binPath -ErrorAction SilentlyContinue
                if ($null -eq $files -or $files.Count -eq 0) {
                    Remove-Item -Path $binPath -Force -ErrorAction SilentlyContinue
                }
            }

            # Remove bin path from User environment PATH
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
        } else {
            Write-Host "Keeping '$binPath' in PATH as the production WinUtil launcher is still installed."
        }

        # Update launcher registry key to keep state in sync
        $registryPath = "HKCU:\Software\WinUtil"
        if (Test-Path $registryPath) {
            Set-ItemProperty -Path $registryPath -Name "DevCommandLauncher" -Value 0 -Type DWord
        }

        Write-Host "WinUtil Dev command launcher uninstalled successfully!" -ForegroundColor Green
    } catch {
        Write-Error "Failed to uninstall WinUtil Dev command launcher. Error: $_"
    }
}
