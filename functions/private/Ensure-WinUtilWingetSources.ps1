function Ensure-WinUtilWingetSources {
    try {
        Write-WinUtilLog -Component "Package" -Message "Resetting WinGet sources..."

        $resetOutput = & winget source reset --force 2>&1
        $resetExitCode = $LASTEXITCODE
        @($resetOutput) | ForEach-Object { Write-WinUtilLog -Component "Package" -Message "winget source reset: $_" }
        if ($resetExitCode -ne 0) {
            throw "winget source reset failed with exit code $resetExitCode."
        }

        $updateOutput = & winget source update 2>&1
        $updateExitCode = $LASTEXITCODE
        @($updateOutput) | ForEach-Object { Write-WinUtilLog -Component "Package" -Message "winget source update: $_" }
        if ($updateExitCode -ne 0) {
            throw "winget source update failed with exit code $updateExitCode."
        }

        # winGet can report a successful source update in a background session
        # without registering the source MSIX for the current user.
        if (-not (Get-AppxPackage -Name "Microsoft.Winget.Source" -ErrorAction SilentlyContinue)) {
            $sourcePackagePath = Join-Path $env:TEMP "Microsoft.Winget.Source.msix"
            try {
                Write-WinUtilLog -Component "Package" -Message "Registering the WinGet source package for the current user..."
                Invoke-WebRequest -Uri "https://cdn.winget.microsoft.com/cache/source2.msix" -OutFile $sourcePackagePath -UseBasicParsing
                Add-AppxPackage -Path $sourcePackagePath -ForceApplicationShutdown -ErrorAction Stop
            } finally {
                Remove-Item -Path $sourcePackagePath -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {
        Write-WinUtilLog -Component "Package" -Message "Ensure-WinUtilWingetSources failed: $_"
        throw
    }
}
