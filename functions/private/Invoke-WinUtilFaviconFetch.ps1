function Complete-WinUtilFaviconFetch {
    param(
        [Parameter(Mandatory = $true)]
        $Operation
    )

    try {
        $results = @($Operation.PowerShell.EndInvoke($Operation.Handle))
        if ($results.Count -gt 0 -and $null -ne $results[0]) {
            $Operation.Bytes = [byte[]]$results[0]
        }

        if ($Operation.Bytes -and $Operation.Bytes.Length -gt 0) {
            try {
                $bitmap = [Windows.Media.Imaging.BitmapImage]::new()
                $bitmap.BeginInit()
                $bitmap.CacheOption = [Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                $bitmap.StreamSource = [System.IO.MemoryStream]::new($Operation.Bytes, $false)
                $bitmap.EndInit()
                $bitmap.Freeze()
                $Operation.TargetImage.Source = $bitmap
                $Operation.TargetImage.Visibility = [Windows.Visibility]::Visible
                $Operation.Fallback.Visibility = [Windows.Visibility]::Collapsed
            } catch {
                $Operation.TargetImage.Visibility = [Windows.Visibility]::Collapsed
                $Operation.Fallback.Visibility = [Windows.Visibility]::Visible
            }
        } else {
            $Operation.TargetImage.Visibility = [Windows.Visibility]::Collapsed
            $Operation.Fallback.Visibility = [Windows.Visibility]::Visible
        }
    } catch {
        $Operation.TargetImage.Visibility = [Windows.Visibility]::Collapsed
        $Operation.Fallback.Visibility = [Windows.Visibility]::Visible
    } finally {
        $Operation.PowerShell.Dispose()
        $Operation.Sync.FaviconOperations.Remove($Operation.AppKey)
    }
}

function Start-WinUtilFaviconPolling {
    if ($sync.FaviconTimer) {
        return
    }

    $sync.FaviconTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $sync.FaviconTimer.Interval = [TimeSpan]::FromMilliseconds(50)
    $sync.FaviconTimer.Add_Tick({
        foreach ($operation in @($sync.FaviconOperations.Values)) {
            if ($operation.Handle.IsCompleted) {
                Complete-WinUtilFaviconFetch -Operation $operation
            }
        }

        if ($sync.FaviconOperations.Count -eq 0) {
            $sync.FaviconTimer.Stop()
            $sync.Remove("FaviconTimer")
        }
    })
    $sync.FaviconTimer.Start()
}

function Invoke-WinUtilFaviconFetch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppKey,

        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [Windows.Controls.Image]$TargetImage,

        [Parameter(Mandatory = $true)]
        [Windows.Controls.TextBlock]$Fallback
    )

    Initialize-WinUtilFaviconRunspacePool | Out-Null

    if ($null -eq $sync.FaviconOperations) {
        $sync.FaviconOperations = [hashtable]::Synchronized(@{})
    }

    $powershell = [powershell]::Create()
    [void]$powershell.AddScript({
        param($faviconUrl, $connectionLimit)

        $response = $null
        $stream = $null
        $memoryStream = $null
        try {
            $request = [System.Net.WebRequest]::Create($faviconUrl)
            $request.Timeout = 5000
            $request.ReadWriteTimeout = 5000
            $request.UserAgent = "WinUtil"
            $request.ServicePoint.ConnectionLimit = $connectionLimit
            $response = $request.GetResponse()
            $stream = $response.GetResponseStream()
            $memoryStream = [System.IO.MemoryStream]::new()
            $stream.CopyTo($memoryStream)
            return ,$memoryStream.ToArray()
        } catch {
            return $null
        } finally {
            if ($stream) { $stream.Dispose() }
            if ($response) { $response.Dispose() }
            if ($memoryStream) { $memoryStream.Dispose() }
        }
    })
    [void]$powershell.AddArgument($Url)
    [void]$powershell.AddArgument($sync.FaviconRunspace.GetMaxRunspaces())
    $powershell.RunspacePool = $sync.FaviconRunspace

    $operation = [pscustomobject]@{
        AppKey       = $AppKey
        PowerShell   = $powershell
        Handle       = $null
        Sync         = $sync
        TargetImage  = $TargetImage
        Fallback     = $Fallback
        Bytes        = $null
    }

    $sync.FaviconOperations[$AppKey] = $operation
    $operation.Handle = $powershell.BeginInvoke()
    Start-WinUtilFaviconPolling
}
