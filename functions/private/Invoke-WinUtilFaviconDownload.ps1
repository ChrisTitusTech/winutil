function Read-WinUtilStreamWithDeadline {
    <#
        .SYNOPSIS
            Reads a response stream without allowing successful partial reads to extend its deadline
    #>
    param(
        [Parameter(Mandatory)]
        $Stream,

        [Parameter(Mandatory)]
        [System.Diagnostics.Stopwatch]$Clock,

        [Parameter(Mandatory)]
        [int]$TimeoutMilliseconds,

        $Request
    )

    $buffer = [byte[]]::new(81920)
    $memory = [System.IO.MemoryStream]::new()
    try {
        while ($true) {
            $remainingMilliseconds = $TimeoutMilliseconds - [int]$Clock.ElapsedMilliseconds
            if ($remainingMilliseconds -le 0) {
                throw [System.TimeoutException]::new("The favicon download exceeded its total deadline.")
            }

            $readTask = $Stream.ReadAsync(
                $buffer,
                0,
                $buffer.Length,
                [System.Threading.CancellationToken]::None
            )
            if (-not $readTask.Wait([int]$remainingMilliseconds)) {
                if ($Request) { $Request.Abort() }
                throw [System.TimeoutException]::new("The favicon download exceeded its total deadline.")
            }
            $readCount = $readTask.Result

            if ($Clock.ElapsedMilliseconds -ge $TimeoutMilliseconds) {
                throw [System.TimeoutException]::new("The favicon download exceeded its total deadline.")
            }
            if ($readCount -le 0) { break }

            $memory.Write($buffer, 0, $readCount)
        }

        return $memory.ToArray()
    } finally {
        $memory.Dispose()
    }
}

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
    $webRequest = $null
    $requestClock = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $requestTimeoutMilliseconds = 5000
        $webRequest = [System.Net.WebRequest]::Create($Request.Url)
        $webRequest.Timeout = $requestTimeoutMilliseconds
        $webRequest.ReadWriteTimeout = $requestTimeoutMilliseconds
        $webRequest.UserAgent = "WinUtil"
        $webRequest.ServicePoint.ConnectionLimit = [Math]::Max(1, [int]$Request.ConnectionLimit)
        $responseTask = $webRequest.GetResponseAsync()
        $remainingMilliseconds = $requestTimeoutMilliseconds - [int]$requestClock.ElapsedMilliseconds
        if ($remainingMilliseconds -le 0 -or
            -not $responseTask.Wait([Math]::Max(1, [int]$remainingMilliseconds))) {
            $webRequest.Abort()
            throw [System.TimeoutException]::new("The favicon download exceeded its total deadline.")
        }
        $response = $responseTask.Result
        $stream = $response.GetResponseStream()
        [byte[]]$bytes = @(Read-WinUtilStreamWithDeadline `
            -Stream $stream `
            -Clock $requestClock `
            -TimeoutMilliseconds $requestTimeoutMilliseconds `
            -Request $webRequest)
        if ($bytes.Count -gt 0) {
            $status = "Success"
        }
    } catch {
        if ($webRequest) {
            try { $webRequest.Abort() } catch { $null = $_ }
        }
        $status = "NetworkFailure"
    } finally {
        $requestClock.Stop()
        try {
            try {
                if ($stream) { $stream.Dispose() }
            } finally {
                if ($response) { $response.Dispose() }
            }
        } finally {
            $sync.FaviconResults.Enqueue([pscustomobject]@{
                AppKey = $Request.AppKey
                Status = $status
                Bytes = $bytes
            })
        }
    }
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
    if ($poolSize -le 1) {
        # A single worker cannot serve optional favicon work without blocking user jobs.
        $sync.FaviconLoadingStopped = $true
        $sync.FaviconQueue.Clear()
        return
    }

    # Leave one worker available for user-requested work. Sixteen concurrent requests restore
    # the throughput of the original non-blocking favicon implementation without letting optional
    # downloads consume the entire shared pool on high-core-count systems.
    $maximumActive = [Math]::Min(16, $poolSize - 1)

    while ($sync.FaviconQueue.Count -gt 0 -and $sync.FaviconInFlight -lt $maximumActive) {
        $pending = $sync.FaviconQueue.Dequeue()
        $workerRequest = [pscustomobject]@{
            AppKey = $pending.AppKey
            Url = $pending.Url
            ConnectionLimit = $maximumActive
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

    $complete = $sync.FaviconInFlight -eq 0 -and
        ($sync.FaviconLoadingStopped -or $null -eq $sync.FaviconQueue -or $sync.FaviconQueue.Count -eq 0)
    if (-not $complete -and $sync.FaviconApplyQueue) {
        $sync.FaviconApplyQueue.Enqueue($true)
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

    Request-WinUtilFaviconDownload
    if ($sync.FaviconLoadingStopped) {
        Stop-WinUtilFaviconLoading -PreserveResults
        return
    }

    $sync.FaviconApplyQueue = [System.Collections.Queue]::new()
    $sync.FaviconApplyQueue.Enqueue($true)
    Start-WinUtilBackgroundQueue -Name "FaviconResults" -Queue $sync.FaviconApplyQueue `
        -RequiresTab "Install" `
        -DeferDelayMilliseconds 50 `
        -Step { Receive-WinUtilFaviconResult } `
        -OnComplete { Stop-WinUtilFaviconLoading -PreserveResults } `
        -DeferWhile {
            $sync.ActiveJob -or
                ($sync.FaviconResults.IsEmpty -and $sync.FaviconInFlight -gt 0)
        }
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
    if ($sync.FaviconApplyQueue) { $sync.FaviconApplyQueue.Clear() }
    if ($sync.FaviconQueue) { $sync.FaviconQueue.Clear() }
    if ($sync.FaviconTargets) { $sync.FaviconTargets.Clear() }
    if (-not $PreserveResults -and $sync.FaviconResults) {
        $discarded = $null
        while ($sync.FaviconResults.TryDequeue([ref]$discarded)) {
            $discarded = $null
        }
    }
}
