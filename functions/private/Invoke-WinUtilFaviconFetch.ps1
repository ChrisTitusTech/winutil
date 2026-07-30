function Initialize-WinUtilFaviconCircuitBreaker {
    <#
        .SYNOPSIS
            Creates the shared thread-safe circuit breaker used by favicon workers.
    #>
    if ($sync.FaviconCircuitBreaker) {
        return
    }

    if (-not ("WinUtilFaviconCircuitBreaker" -as [type])) {
        # Workers share this compiled reference type so failure counting and cancellation
        # remain atomic across runspaces without relying on PowerShell thread affinity.
        Add-Type @"
using System;
using System.Threading;

public sealed class WinUtilFaviconCircuitBreaker : IDisposable
{
    private readonly object gate = new object();
    private readonly int threshold;
    private readonly CancellationTokenSource cancellation = new CancellationTokenSource();
    private int consecutiveFailures;

    public WinUtilFaviconCircuitBreaker(int threshold)
    {
        if (threshold <= 0)
        {
            throw new ArgumentOutOfRangeException("threshold", "Threshold must be greater than zero.");
        }

        this.threshold = threshold;
    }

    public bool IsCancellationRequested
    {
        get { return cancellation.IsCancellationRequested; }
    }

    public int ConsecutiveFailures
    {
        get
        {
            lock (gate)
            {
                return consecutiveFailures;
            }
        }
    }

    public void ReportSuccess()
    {
        lock (gate)
        {
            if (!cancellation.IsCancellationRequested)
            {
                consecutiveFailures = 0;
            }
        }
    }

    public void ReportFailure()
    {
        lock (gate)
        {
            if (cancellation.IsCancellationRequested)
            {
                return;
            }

            consecutiveFailures++;
            if (consecutiveFailures >= threshold)
            {
                cancellation.Cancel();
            }
        }
    }

    public void Cancel()
    {
        cancellation.Cancel();
    }

    public void Dispose()
    {
        cancellation.Dispose();
    }
}
"@
    }

    # Eight consecutive transport failures strongly indicate that Google is unavailable.
    $failureThreshold = 8
    $sync.FaviconCircuitBreaker = [WinUtilFaviconCircuitBreaker]::new($failureThreshold)
}

function Complete-WinUtilFaviconFetch {
    <#
        .SYNOPSIS
            Completes one favicon operation and updates its WPF image or fallback text.
        .PARAMETER Operation
            The asynchronous favicon operation and its associated WPF controls.
    #>
    param(
        [Parameter(Mandatory = $true)]
        $Operation
    )

    try {
        $results = @($Operation.PowerShell.EndInvoke($Operation.Handle))
        if ($results.Count -eq 0 -or $null -eq $results[0]) {
            throw "Favicon worker returned no result."
        }

        $result = $results[0]

        if ($result.Status -eq "Success" -and $result.Bytes) {
            $Operation.Bytes = [byte[]]$result.Bytes
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
    <#
        .SYNOPSIS
            Starts dispatcher-based polling for completed favicon operations.
    #>
    if ($sync.FaviconTimer) {
        return
    }

    $pollIntervalMilliseconds = 50
    $sync.FaviconTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $sync.FaviconTimer.Interval = [TimeSpan]::FromMilliseconds($pollIntervalMilliseconds)
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
    <#
        .SYNOPSIS
            Queues one application favicon for bounded background downloading.
        .PARAMETER AppKey
            The unique application key associated with the favicon operation.
        .PARAMETER Url
            The favicon service URL to download.
        .PARAMETER TargetImage
            The WPF image control that receives the downloaded favicon.
        .PARAMETER Fallback
            The WPF text control displayed when the favicon is unavailable.
    #>
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

    Initialize-WinUtilFaviconCircuitBreaker
    if ($sync.FaviconCircuitBreaker.IsCancellationRequested) {
        return
    }

    Initialize-WinUtilFaviconRunspacePool | Out-Null
    if ($null -eq $sync.FaviconOperations) {
        $sync.FaviconOperations = [hashtable]::Synchronized(@{})
    }

    $requestTimeoutMilliseconds = 5000
    $powershell = [powershell]::Create()
    [void]$powershell.AddScript({
        param($faviconUrl, $connectionLimit, $circuitBreaker, $requestTimeoutMilliseconds)

        if ($circuitBreaker.IsCancellationRequested) {
            return [pscustomobject]@{
                Status = "Cancelled"
                Bytes  = $null
            }
        }

        $response = $null
        $stream = $null
        $memoryStream = $null
        try {
            $request = [System.Net.WebRequest]::Create($faviconUrl)
            $request.Timeout = $requestTimeoutMilliseconds
            $request.ReadWriteTimeout = $requestTimeoutMilliseconds
            $request.UserAgent = "WinUtil"
            $request.ServicePoint.ConnectionLimit = $connectionLimit
            $response = $request.GetResponse()
            $stream = $response.GetResponseStream()
            $memoryStream = [System.IO.MemoryStream]::new()
            $stream.CopyTo($memoryStream)
            $circuitBreaker.ReportSuccess()
            return [pscustomobject]@{
                Status = "Success"
                Bytes  = $memoryStream.ToArray()
            }
        } catch {
            $circuitBreaker.ReportFailure()
            return [pscustomobject]@{
                Status = "NetworkFailure"
                Bytes  = $null
            }
        } finally {
            if ($stream) { $stream.Dispose() }
            if ($response) { $response.Dispose() }
            if ($memoryStream) { $memoryStream.Dispose() }
        }
    })
    [void]$powershell.AddArgument($Url)
    [void]$powershell.AddArgument($sync.FaviconRunspace.GetMaxRunspaces())
    [void]$powershell.AddArgument($sync.FaviconCircuitBreaker)
    [void]$powershell.AddArgument($requestTimeoutMilliseconds)
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

    if ($sync.FaviconCircuitBreaker.IsCancellationRequested) {
        $powershell.Dispose()
        return
    }

    $sync.FaviconOperations[$AppKey] = $operation
    $operation.Handle = $powershell.BeginInvoke()
    Start-WinUtilFaviconPolling
}
