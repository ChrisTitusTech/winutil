Function Install-WinUtilProgramDirect {
    <#
    .SYNOPSIS
        Downloads and runs an installer from a direct URL - for packages with no winget/choco listing.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Packages
    )

    foreach ($package in $Packages) {
        $name = $package.content
        $url = $package.url
        $installArgs = $package.args

        if ([string]::IsNullOrWhiteSpace($url)) {
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "Direct install for $name is missing a url."
            continue
        }

        $ext = [IO.Path]::GetExtension($url)
        if ([string]::IsNullOrEmpty($ext)) { $ext = ".exe" }
        $dest = Join-Path $env:TEMP "$name$ext"

        Write-WinUtilLog -Component "Package" -Message "Downloading $name from $url"
        try {
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -TimeoutSec 60
        } catch {
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "Failed to download ${name}: $_"
            continue
        }

        Write-WinUtilLog -Component "Package" -Message "Installing $name"
        try {
            if ($ext -eq ".msi") {
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$dest`" $installArgs" -Wait
                Write-WinUtilLog -Component "Package" -Message "$name installed."
                Remove-Item $dest -Force -ErrorAction SilentlyContinue
            } elseif ([string]::IsNullOrWhiteSpace($installArgs)) {
                # No documented silent-install flag, so this runs interactively - and some
                # interactive installers (e.g. Channels DVR Server) launch a long-running
                # application on completion that never exits, which would make -Wait block
                # forever. Launch and move on instead of waiting; don't delete the downloaded
                # file since the process may still be reading it after we return.
                $proc = Start-Process -FilePath $dest -PassThru
                Set-WinUtilProcessForeground -Process $proc
                Write-WinUtilLog -Component "Package" -Message "$name installer launched - it may need you to finish a setup wizard. WinUtil will not wait for it to close."
            } else {
                Start-Process -FilePath $dest -ArgumentList $installArgs -Wait
                Write-WinUtilLog -Component "Package" -Message "$name installed."
                Remove-Item $dest -Force -ErrorAction SilentlyContinue
            }
        } catch {
            Write-WinUtilLog -Level "ERROR" -Component "Package" -Message "Failed to run installer for ${name}: $_"
            Remove-Item $dest -Force -ErrorAction SilentlyContinue
        }
    }
}
