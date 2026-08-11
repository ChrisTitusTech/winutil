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
                $message = "Failed to query releases for ${repo}: $($_.Exception.Message)"
                Write-WinUtilLog -Level "ERROR" -Component "Package" -Message $message
                throw $message
            }
        }

        if (-not $release) {
            $message = "No releases found for $repo"
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message $message
            throw $message
        }

        $asset = $release.assets | Where-Object { $_.name -like $assetPattern } | Select-Object -First 1
        if (-not $asset) {
            $message = "No asset matching '$assetPattern' found in latest release of $repo"
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message $message
            throw $message
        }

        $downloadDirectory = Join-Path $env:PUBLIC "Downloads\WinUtil"
        New-Item -ItemType Directory -Path $downloadDirectory -Force | Out-Null

        $dest = Join-Path $downloadDirectory $asset.name
        Write-WinUtilLog -Component "Package" -Message "Downloading $($asset.name) for $name"
        try {
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $dest -UseBasicParsing -TimeoutSec 120
        } catch {
            $message = "GitHub install for $name is missing repo/assetPattern."
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message $message
            throw $message
        }

        Write-WinUtilLog -Component "Package" -Message "Installing $name"
        try {
            if ($dest -like "*.msi") {
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$dest`"" -Wait
                Write-WinUtilLog -Component "Package" -Message "$name installed."
                Remove-Item $dest -Force -ErrorAction SilentlyContinue
            } else {
                if ($package.runAsDesktopUser -eq $true) {
                    Start-WinUtilProcessAsDesktopUser -FilePath $dest

                    Write-WinUtilLog -Component "Package" -Message "$name installer launched as the desktop user. WinUtil will not wait for its setup wizard to close."
                } else {
                    Start-Process -FilePath $dest

                    Write-WinUtilLog -Component "Package" -Message "$name installer launched. WinUtil will not wait for its setup wizard to close."
    }
}
        } catch {
            $message = "Failed to run installer for ${name}: $($_.Exception.Message)"
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message $message
            Remove-Item $dest -Force -ErrorAction SilentlyContinue
            throw $message
        }
    }
}
