Function Install-WinUtilProgramGithub {
    <#
    .SYNOPSIS
        Downloads and runs the newest matching release asset from a GitHub repo - for
        Channels DVR community projects not published to winget/choco.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Packages
    )

    $headers = @{ "User-Agent" = "cdvr-winutil" }

    foreach ($package in $Packages) {
        $name = $package.content
        $repo = $package.repo
        $assetPattern = $package.assetPattern

        if ([string]::IsNullOrWhiteSpace($repo) -or [string]::IsNullOrWhiteSpace($assetPattern)) {
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "GitHub install for $name is missing repo/assetPattern."
            continue
        }

        Write-WinUtilLog -Component "Package" -Message "Querying latest release for $repo"
        $release = $null
        try {
            $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" -Headers $headers -TimeoutSec 30
        } catch {
            # /releases/latest 404s when the repo's newest release is marked prerelease
            # (e.g. RustDVR's only release, v0.0.1) - fall back to the full release list.
            try {
                $allReleases = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases" -Headers $headers -TimeoutSec 30
                $release = $allReleases | Select-Object -First 1
            } catch {
                Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "Failed to query releases for ${repo}: $_"
                continue
            }
        }

        if (-not $release) {
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "No releases found for $repo"
            continue
        }

        $asset = $release.assets | Where-Object { $_.name -like $assetPattern } | Select-Object -First 1
        if (-not $asset) {
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "No asset matching '$assetPattern' found in latest release of $repo"
            continue
        }

        $dest = Join-Path $env:TEMP $asset.name
        Write-WinUtilLog -Component "Package" -Message "Downloading $($asset.name) for $name"
        try {
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $dest -UseBasicParsing -TimeoutSec 120
        } catch {
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "Failed to download ${name}: $_"
            continue
        }

        Write-WinUtilLog -Component "Package" -Message "Installing $name"
        try {
            if ($dest -like "*.msi") {
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$dest`"" -Wait
                Write-WinUtilLog -Component "Package" -Message "$name installed."
                Remove-Item $dest -Force -ErrorAction SilentlyContinue
            } else {
                # No known silent-install flag for these community-released installers, so this
                # runs interactively - and some interactive installers launch a long-running
                # application on completion that never exits, which would make -Wait block
                # forever. Launch and move on instead of waiting; don't delete the downloaded
                # file since the process may still be reading it after we return.
                $proc = Start-Process -FilePath $dest -PassThru
                Set-WinUtilProcessForeground -Process $proc
                Write-WinUtilLog -Component "Package" -Message "$name installer launched - it may need you to finish a setup wizard. WinUtil will not wait for it to close."
            }
        } catch {
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "Failed to run installer for ${name}: $_"
            Remove-Item $dest -Force -ErrorAction SilentlyContinue
        }
    }
}
