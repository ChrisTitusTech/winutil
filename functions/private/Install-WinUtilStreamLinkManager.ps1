Function Install-WinUtilStreamLinkManager {
    <#
    .SYNOPSIS
        Installs Streaming Library Manager natively, without running the upstream slm.bat
        installer.

    .DESCRIPTION
        slm.bat's own "install" command requires an interactive Y/N keypress via the batch
        "choice" builtin, with no documented silent flag - not automatable without piping
        input past the prompt as a workaround. Instead, this replicates slm.bat's underlying
        steps directly (per its source at .../executables/slm.bat): download the same packaged
        Windows release, extract it into a fixed install directory, then register and start it,
        rather than relying on the batch script at all.

        The download itself is a Dropbox link hardcoded in slm.bat - there's no GitHub release
        asset for this app - so this has a real, if unavoidable, dependency on a link the
        project maintainer controls rather than a versioned GitHub artifact.

        No uninstall is documented upstream either. Because this owns the entire install
        location, Uninstall-WinUtilStreamLinkManager can safely remove it outright: stop the
        process, unregister the scheduled task, delete the install directory.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Packages
    )

    # Same link slm.bat itself downloads from for a normal (non-prerelease) install.
    $downloadUrl = "https://www.dropbox.com/scl/fi/apw33xi80jjivyjp9rxb4/slm_windows.zip?rlkey=1m5zj7qz9ittguispsi00nyar&dl=1"
    $taskName = "Streaming Library Manager"

    foreach ($package in $Packages) {
        $name = $package.content
        $installDir = Join-Path $env:LocalAppData "StreamLinkManager"
        $zipPath = Join-Path $env:TEMP "slm_windows_$([guid]::NewGuid().ToString('N')).zip"
        $extractPath = Join-Path $env:TEMP "slm_windows_extract_$([guid]::NewGuid().ToString('N'))"

        Write-WinUtilLog -Component "Package" -Message "Installing $name to $installDir"
        try {
            # Stop any running instance first so its files aren't locked during overwrite -
            # slm.bat does the same before it re-extracts over an existing install.
            Get-Process -Name "slm" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

            New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

            Write-WinUtilLog -Component "Package" -Message "Downloading $name"
            Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing -TimeoutSec 120

            Write-WinUtilLog -Component "Package" -Message "Extracting $name"
            Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

            if (-not (Test-Path $installDir)) {
                New-Item -ItemType Directory -Path $installDir -Force | Out-Null
            }
            Copy-Item -Path (Join-Path $extractPath '*') -Destination $installDir -Recurse -Force

            $exePath = Join-Path $installDir "slm.exe"
            if (-not (Test-Path $exePath)) {
                throw "slm.exe not found in the extracted package - the upstream release layout may have changed."
            }

            # Register it to start at logon, matching slm.bat's own "startup" command
            # (schtasks .../rl highest). WinUtil already runs elevated, so - unlike slm.bat,
            # which re-elevates separately for this - the task can be registered directly.
            $runCommand = "powershell -NoProfile -WindowStyle Hidden -Command `"Start-Process -WindowStyle Hidden '$exePath'`""
            & schtasks /create /tn $taskName /tr $runCommand /sc onlogon /rl highest /f | Out-Null

            Write-WinUtilLog -Component "Package" -Message "Starting $name"
            Start-Process -WindowStyle Hidden -FilePath $exePath

            Write-WinUtilLog -Component "Package" -Message "$name installed and started - web interface at $($package.webui)"
        } catch {
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "Failed to install ${name}: $_"
        } finally {
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
            Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
