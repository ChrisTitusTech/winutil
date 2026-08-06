function Invoke-WinUtilWinGetCommand {
    <#
        .SYNOPSIS
            Runs a Microsoft.WinGet.Client command and reports its progress as it goes

        .DESCRIPTION
            The module reports progress through the PowerShell progress stream, which cannot be
            redirected like output or errors. Running the command on a nested PowerShell
            instance makes that stream readable, so download and install percentages can be
            polled while the command is still running.

        .PARAMETER Command
            The cmdlet to run, for example Install-WinGetPackage.

        .PARAMETER Parameters
            Arguments for the cmdlet.

        .PARAMETER ProgressBase
            Where this command starts within the job's overall progress bar.

        .PARAMETER ProgressSpan
            How much of the overall bar this command accounts for. Zero reports nothing.

        .PARAMETER Label
            Text shown before the module's own status, normally the package name.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [hashtable]$Parameters = @{},

        [int]$ProgressBase = 0,

        [int]$ProgressSpan = 0,

        [string]$Label
    )

    $shell = [powershell]::Create()
    try {
        [void]$shell.AddCommand("Import-Module").AddParameter("Name", "Microsoft.WinGet.Client")
        [void]$shell.AddStatement().AddCommand($Command)
        foreach ($entry in $Parameters.GetEnumerator()) {
            [void]$shell.AddParameter($entry.Key, $entry.Value)
        }

        $handle = $shell.BeginInvoke()

        # The module reports a download as a percentage but an install only as 0 then 100, and
        # the install is often half the wall-clock time. Giving the download the first half of
        # the slice keeps the bar from looking finished while the installer is still running.
        $downloadShare = 0.5
        $started = [System.Diagnostics.Stopwatch]::StartNew()
        $reported = ""
        $indeterminate = $false

        # A byte sample can be superseded within milliseconds, so the whole collection is
        # scanned rather than only its last entry. The records accumulate, so nothing is lost
        # to a slow poll.
        $downloadPattern = '[\d.]+\s*[KMGT]?B\s*/'
        $lastPercent = -1

        while (-not $handle.IsCompleted) {
            $records = @($shell.Streams.Progress)
            $latest = $records[-1]
            if ($latest) {
                $measured = @($records | Where-Object { $_.StatusDescription -match $downloadPattern -and $_.PercentComplete -ge 0 })
                $downloading = $latest.StatusDescription -match "^\s*Downloading" -or $latest.StatusDescription -match $downloadPattern

                if ($downloading -and $ProgressSpan -gt 0) {
                    if ($indeterminate) {
                        Write-WinUtilJobProgress -State "Normal"
                        $indeterminate = $false
                    }
                    $best = if ($measured.Count -gt 0) { ($measured | Measure-Object -Property PercentComplete -Maximum).Maximum } else { 0 }
                    $percent = $ProgressBase + [int](($best / 100) * $ProgressSpan * $downloadShare)
                    if ($percent -ne $lastPercent -or $latest.StatusDescription -ne $reported) {
                        Write-WinUtilJobProgress -Status "$Label - $($latest.StatusDescription)" -Percent $percent
                        $lastPercent = $percent
                        $reported = $latest.StatusDescription
                    }
                } else {
                    # The installer reports nothing until it exits, so show that it is running
                    if (-not $indeterminate -and $ProgressSpan -gt 0) {
                        Write-WinUtilJobProgress -Percent ($ProgressBase + [int]($ProgressSpan * $downloadShare)) -State "Indeterminate"
                        $indeterminate = $true
                    }
                    $status = "$Label - $($latest.StatusDescription) ($([int]$started.Elapsed.TotalSeconds)s)"
                    if ($status -ne $reported) {
                        Write-WinUtilJobProgress -Status $status
                        $reported = $status
                    }
                }
            }
            Start-Sleep -Milliseconds 100
        }

        if ($indeterminate) {
            Write-WinUtilJobProgress -State "Normal"
        }

        $output = $shell.EndInvoke($handle)

        foreach ($record in $shell.Streams.Error) {
            Write-WinUtilErrorRecord -ErrorRecord $record -Component "Package" -Context $Command
        }
        foreach ($record in $shell.Streams.Warning) {
            Write-WinUtilLog -Level "WARN" -Component "Package" -Message $record.Message
        }

        return @($output)
    } finally {
        $shell.Dispose()
    }
}
