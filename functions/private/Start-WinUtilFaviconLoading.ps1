function Start-WinUtilFaviconLoading {
    <#
        .SYNOPSIS
            Downloads an app icon while the rest of the app list renders.
    #>
    param(
        [Windows.Controls.Image]$Image,
        [Windows.Controls.TextBlock]$Fallback,
        [string]$Url
    )

    $null = Invoke-WPFRunspace -ArgumentList @{ Image = $Image; Fallback = $Fallback; Url = $Url } -ScriptBlock {
        param($Icon)

        $response = $null
        $stream = [IO.MemoryStream]::new()
        try {
            $request = [System.Net.WebRequest]::Create($Icon.Url)
            $request.Timeout = 5000
            $request.ReadWriteTimeout = 5000
            $response = $request.GetResponse()
            $response.GetResponseStream().CopyTo($stream)
            $bytes = $stream.ToArray()
        } catch {
            # An unavailable icon leaves the letter fallback already on screen.
            return
        } finally {
            if ($response) { $response.Dispose() }
            $stream.Dispose()
        }

        Invoke-WPFUIThread -Async -Parameters @{ Image = $Icon.Image; Fallback = $Icon.Fallback; Bytes = $bytes } -ScriptBlock {
            param($Image, $Fallback, $Bytes)
            Complete-WinUtilFaviconLoading -Image $Image -Fallback $Fallback -Bytes $Bytes
        }
    }
}

function Complete-WinUtilFaviconLoading {
    param(
        [Windows.Controls.Image]$Image,
        [Windows.Controls.TextBlock]$Fallback,
        [byte[]]$Bytes
    )

    if (-not (Test-WinUtilUIAlive)) { return }

    $stream = [IO.MemoryStream]::new($Bytes, $false)
    try {
        # Avoid WPF's process-cached URI loader, which can retain a COM object from a closed UI thread.
        $bitmap = [Windows.Media.Imaging.BitmapImage]::new()
        $bitmap.BeginInit()
        $bitmap.CacheOption = [Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.StreamSource = $stream
        $bitmap.EndInit()
        $bitmap.Freeze()
        $Image.Source = $bitmap
        $Image.Visibility = "Visible"
        $Fallback.Visibility = "Collapsed"
    } catch {
        # A failed decode must not prevent the app entry from being usable.
        $Image.Visibility = "Collapsed"
        $Fallback.Visibility = "Visible"
    } finally {
        $stream.Dispose()
    }
}
