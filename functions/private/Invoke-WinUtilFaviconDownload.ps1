function Invoke-WinUtilFaviconDownload {
    <#
        .SYNOPSIS
            Downloads one favicon on the shared worker pool and publishes its bytes

        .DESCRIPTION
            The worker receives only strings and writes only a plain result object. WPF controls
            remain owned by the interface thread and are resolved there by AppKey.

        .PARAMETER Request
            The application key and favicon URL to download.
    #>
    param(
        [Parameter(Mandatory)]
        $Request
    )

    $status = "NetworkFailure"
    $bytes = $null
    $response = $null
    $stream = $null
    $memory = $null
    try {
        $requestTimeoutMilliseconds = 5000
        $webRequest = [System.Net.WebRequest]::Create($Request.Url)
        $webRequest.Timeout = $requestTimeoutMilliseconds
        $webRequest.ReadWriteTimeout = $requestTimeoutMilliseconds
        $webRequest.UserAgent = "WinUtil"
        $response = $webRequest.GetResponse()
        $stream = $response.GetResponseStream()
        $memory = [System.IO.MemoryStream]::new()
        $stream.CopyTo($memory)
        $bytes = $memory.ToArray()
        if ($bytes.Count -gt 0) {
            $status = "Success"
        }
    } catch {
        $status = "NetworkFailure"
    } finally {
        if ($stream) { $stream.Dispose() }
        if ($response) { $response.Dispose() }
        if ($memory) { $memory.Dispose() }
    }

    $sync.FaviconResults.Enqueue([pscustomobject]@{
        AppKey = $Request.AppKey
        Status = $status
        Bytes = $bytes
    })
}

function Request-WinUtilFaviconDownload {
    <#
        .SYNOPSIS
            Fills a bounded share of the worker pool from the pending favicon queue
    #>

    if ($sync.FaviconLoadingStopped -or $sync.ActiveJob -or
        $null -eq $sync.FaviconQueue -or $null -eq $sync.FaviconTargets) {
        return
    }

    Initialize-WinUtilRunspacePool | Out-Null
    $poolSize = [Math]::Max(1, $sync.runspace.GetMaxRunspaces())
    # Leave at least half of a multi-thread pool available for user-requested work. Favicon
    # requests are optional background work and must not become the next source of job latency.
    $maximumActive = [Math]::Min(4, [Math]::Max(1, [Math]::Floor($poolSize / 2)))

    while ($sync.FaviconQueue.Count -gt 0 -and $sync.FaviconInFlight -lt $maximumActive) {
        $pending = $sync.FaviconQueue.Dequeue()
        $workerRequest = [pscustomobject]@{
            AppKey = $pending.AppKey
            Url = $pending.Url
        }

        $sync.FaviconTargets[$pending.AppKey] = [pscustomobject]@{
            TargetImage = $pending.TargetImage
            Fallback = $pending.Fallback
        }

        try {
            $handle = Invoke-WPFRunspace -ScriptBlock {
                param($FaviconRequest)
                Invoke-WinUtilFaviconDownload -Request $FaviconRequest
            } -ArgumentList $workerRequest

            if ($null -eq $handle) {
                throw "The shared worker pool refused the favicon request."
            }
            $sync.FaviconInFlight++
        } catch {
            [void]$sync.FaviconTargets.Remove($pending.AppKey)
            $sync.FaviconLoadingStopped = $true
            $sync.FaviconQueue.Clear()
            break
        }
    }
}

function Receive-WinUtilFaviconResult {
    <#
        .SYNOPSIS
            Applies completed favicon downloads on the interface thread
    #>

    $result = $null
    while ($sync.FaviconResults.TryDequeue([ref]$result)) {
        $sync.FaviconInFlight = [Math]::Max(0, $sync.FaviconInFlight - 1)
        $target = $sync.FaviconTargets[$result.AppKey]
        [void]$sync.FaviconTargets.Remove($result.AppKey)
        if ($null -eq $target) {
            $result = $null
            continue
        }

        $loaded = $false
        if ($result.Status -eq "Success" -and $result.Bytes) {
            try {
                $bitmap = [Windows.Media.Imaging.BitmapImage]::new()
                $bitmap.BeginInit()
                $bitmap.CacheOption = [Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                $imageStream = [System.IO.MemoryStream]::new([byte[]]$result.Bytes, $false)
                try {
                    $bitmap.StreamSource = $imageStream
                    $bitmap.EndInit()
                } finally {
                    $imageStream.Dispose()
                }
                $bitmap.Freeze()
                $target.TargetImage.Source = $bitmap
                $target.TargetImage.Visibility = [System.Windows.Visibility]::Visible
                $target.Fallback.Visibility = [System.Windows.Visibility]::Collapsed
                $sync.FaviconConsecutiveFailures = 0
                $loaded = $true
            } catch {
                $loaded = $false
            }
        }

        if (-not $loaded) {
            $target.TargetImage.Visibility = [System.Windows.Visibility]::Collapsed
            $target.Fallback.Visibility = [System.Windows.Visibility]::Visible
            $sync.FaviconConsecutiveFailures++
            if ($sync.FaviconConsecutiveFailures -ge 8) {
                $sync.FaviconLoadingStopped = $true
                $sync.FaviconQueue.Clear()
            }
        }

        $result = $null
    }

    Request-WinUtilFaviconDownload

    if ($sync.FaviconInFlight -eq 0 -and
        ($sync.FaviconLoadingStopped -or $null -eq $sync.FaviconQueue -or $sync.FaviconQueue.Count -eq 0)) {
        Stop-WinUtilFaviconLoading -PreserveResults
    }
}

function Start-WinUtilFaviconLoading {
    <#
        .SYNOPSIS
            Starts deferred favicon loading after install entries finish rendering
    #>

    if ($null -eq $sync.FaviconQueue -or $sync.FaviconQueue.Count -eq 0 -or
        -not (Test-WinUtilUIAlive)) {
        return
    }

    $sync.FaviconResults = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    $sync.FaviconTargets = [hashtable]::Synchronized(@{})
    $sync.FaviconInFlight = 0
    $sync.FaviconConsecutiveFailures = 0
    $sync.FaviconLoadingStopped = $false

    $sync.FaviconTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $sync.FaviconTimer.Interval = [TimeSpan]::FromMilliseconds(100)
    $sync.FaviconTimer.Add_Tick({ Receive-WinUtilFaviconResult })
    $sync.FaviconTimer.Start()

    Request-WinUtilFaviconDownload
}

function Stop-WinUtilFaviconLoading {
    <#
        .SYNOPSIS
            Stops favicon result polling and drops pending optional work

        .PARAMETER PreserveResults
            Keeps completed-result state available until the shared pool finishes cleanup.
    #>
    param(
        [switch]$PreserveResults
    )

    $sync.FaviconLoadingStopped = $true
    if ($sync.FaviconTimer) {
        $sync.FaviconTimer.Stop()
        $sync.Remove("FaviconTimer")
    }
    if ($sync.FaviconQueue) { $sync.FaviconQueue.Clear() }
    if ($sync.FaviconTargets) { $sync.FaviconTargets.Clear() }
    if (-not $PreserveResults -and $sync.FaviconResults) {
        $discarded = $null
        while ($sync.FaviconResults.TryDequeue([ref]$discarded)) {
            $discarded = $null
        }
    }
}
