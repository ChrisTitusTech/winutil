function Get-WinUtilAppIcon {
    <#
        .SYNOPSIS
            Returns the bundled icon for an app on the Install tab

        .DESCRIPTION
            Icons ship inside the script as base64 PNGs, one per app, taken from config/icons/<key>.png
            at compile time, so the Install tab needs no network access to draw them and nothing is
            waiting on a favicon service.

            Each icon is decoded once into a frozen bitmap, which WPF can share between entries,
            threads and windows. It is kept in memory for the rest of the session and never written
            to disk.

        .PARAMETER Key
            The app key as written in config/applications.json, without the WPFInstall prefix.
            It is also the name of the icon's file.

        .OUTPUTS
            A frozen bitmap when the app has a bundled icon.
            $null when the app has no icon file or it cannot be decoded, so the caller can look the
            icon up online.
    #>
    param([Parameter(Mandatory)][string]$Key)

    if ($null -eq $script:WinUtilAppIconCache) {
        $script:WinUtilAppIconCache = @{}
    }
    if ($script:WinUtilAppIconCache.ContainsKey($Key)) {
        return $script:WinUtilAppIconCache[$Key]
    }

    $icon = $null
    $entry = if ($sync.configs.icons) { $sync.configs.icons.PSObject.Properties[$Key] }
    if ($entry) {
        try {
            # Decoding the frame directly is about a third faster than going through BitmapImage
            $stream = [IO.MemoryStream]::new([Convert]::FromBase64String($entry.Value))
            $frame = [Windows.Media.Imaging.BitmapFrame]::Create($stream, [Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat, [Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
            $frame.Freeze()
            $stream.Dispose()
            $icon = $frame
        } catch {
            Write-Debug "Bundled icon for $Key could not be decoded: $_"
        }
    }

    $script:WinUtilAppIconCache[$Key] = $icon
    return $icon
}
