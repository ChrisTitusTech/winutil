function Start-WinUtilJob {
    <#
        .SYNOPSIS
            Runs a long operation off the UI thread with the shared progress, taskbar, log and
            error handling applied around it

        .DESCRIPTION
            One job at a time. Owns the busy flag, the progress bar, the taskbar item, the
            console banner and the log lines for the job's lifetime. The body does the work and
            calls Step-WinUtilJob; it must not print a banner or set the busy flag itself. A body
            that throws is caught and the interface restored in a finally, so a failure cannot
            leave the UI stuck busy.

        .PARAMETER Name
            Log component and progress text, for example Install.

        .PARAMETER ScriptBlock
            The work. Receives Parameters as named parameters.

        .PARAMETER Parameters
            Values passed to the body by name.

        .PARAMETER Description
            Progress text shown while the job starts. Defaults to the job name.

        .PARAMETER DisableAppList
            Greys out the app list for the duration, for jobs that change what is installed.

        .EXAMPLE
            Start-WinUtilJob -Name "Install" -Parameters @{ Packages = $packages } -ScriptBlock {
                param($Packages)
                Step-WinUtilJob -Status "Installing" -Percent 10
            }
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [hashtable]$Parameters = @{},

        [string]$Description,

        [switch]$DisableAppList
    )

    if ($sync.ShuttingDown -or $sync.FinishInConsole) {
        Write-WinUtilLog -Level "WARN" -Component $Name -Message "Refused to start $Name, WinUtil is closing."
        return $null
    }

    # A nested job runs inline: the outer already owns the slot and the reporting, so claiming
    # again would refuse it and skip its work. Feature installs arrive twice, from feature.json
    # and from Invoke-WPFFeatureInstall.
    if ($global:WinUtilIsJobWorker) {
        & $ScriptBlock @Parameters
        return $null
    }

    # Locked: a headless or scheduled caller is not serialised by the dispatcher, where
    # test-then-assign lets two jobs both own the slot. The token identifies the run, so a worker
    # still unwinding cannot release a slot the next job holds.
    $jobToken = [guid]::NewGuid().ToString()
    $blockedBy = $null
    [System.Threading.Monitor]::Enter($sync.SyncRoot)
    try {
        if ($sync.ActiveJob) {
            $blockedBy = $sync.ActiveJob
        } else {
            $sync.ActiveJob = $Name
            $sync.ActiveJobToken = $jobToken
        }
    } finally {
        [System.Threading.Monitor]::Exit($sync.SyncRoot)
    }

    if ($blockedBy) {
        Show-WinUtilMessage -Message "$blockedBy is still running. Wait for it to finish before starting another action." -Title "WinUtil" -Button "OK" -Icon "Warning" | Out-Null
        return $null
    }

    $label = if ($Description) { $Description } else { $Name }
    Write-WinUtilLog -Component $Name -Message "$Name job started."
    Write-WinUtilJobBanner -Message $label
    Step-WinUtilJob -Status "$label..." -Percent 0 -State "Normal" -Overlay "logo"

    if ($DisableAppList -and (Test-WinUtilUIAlive)) {
        Invoke-WPFUIThread -ScriptBlock {
            if ($null -ne $sync.ItemsControl) { $sync.ItemsControl.IsEnabled = $false }
        }
    }

    # Rebuilt from its text inside the runspace: a scriptblock carries the session state it was
    # defined in, and recreating it there binds it to the worker. The handle is discarded,
    # printing it puts an IAsyncResult table on the console on every button press.
    $null = Invoke-WPFRunspace -ParameterList @(
        ("JobName", $Name),
        ("JobLabel", $label),
        ("JobBody", $ScriptBlock.ToString()),
        ("JobParameters", $Parameters),
        ("JobRestoresAppList", [bool]$DisableAppList),
        ("JobToken", $jobToken)
    ) -ScriptBlock {
        param($JobName, $JobLabel, $JobBody, $JobParameters, $JobRestoresAppList, $JobToken)

        # Marks this runspace as the one doing the work, so a pause holds here and not in
        # whoever asked for it
        $global:WinUtilIsJobWorker = $true

        $jobClock = [System.Diagnostics.Stopwatch]::StartNew()
        $errorsBefore = if ($sync.LoggedErrors) { $sync.LoggedErrors.Count } else { 0 }
        try {
            $body = [scriptblock]::Create($JobBody)

            # A worker's warning and error streams buffer on a PowerShell object nobody reads.
            # Merging them into the output stream is what gets them to the log.
            & $body @JobParameters 2>&1 3>&1 | ForEach-Object {
                if ($_ -is [System.Management.Automation.WarningRecord]) {
                    Write-WinUtilLog -Level "WARN" -Component $JobName -Message $_.Message
                } elseif ($_ -is [System.Management.Automation.ErrorRecord]) {
                    Write-WinUtilErrorRecord -ErrorRecord $_ -Component $JobName -Context "Non-terminating error"
                }
            }

            $jobClock.Stop()

            # A step can fail without throwing, for example a registry write refused by policy
            $newErrors = if ($sync.LoggedErrors) { $sync.LoggedErrors.Count - $errorsBefore } else { 0 }
            if ($newErrors -gt 0) {
                Write-WinUtilLog -Level "WARN" -Component $JobName -Message "$JobName job finished in $($jobClock.ElapsedMilliseconds) ms with $newErrors error(s)."
                Write-WinUtilJobBanner -Message "$JobLabel finished with $newErrors error(s), see the log" -Level "ERROR"
                Step-WinUtilJob -Status "$JobName finished with $newErrors error(s)" -Percent 100 -State "Paused" -Overlay "warning"
            } else {
                Write-WinUtilLog -Component $JobName -Message "$JobName job finished in $($jobClock.ElapsedMilliseconds) ms."
                Write-WinUtilJobBanner -Message "$JobLabel finished"
                Step-WinUtilJob -Status "$JobName finished" -Percent 100 -State "None" -Overlay "checkmark"
            }
        } catch {
            $jobClock.Stop()
            Write-WinUtilErrorRecord -ErrorRecord $_ -Component $JobName -Context "$JobName failed after $($jobClock.ElapsedMilliseconds) ms"
            Write-WinUtilJobBanner -Message "$JobLabel failed: $($_.Exception.Message)" -Level "ERROR"
            Step-WinUtilJob -Status "$JobName failed" -Percent 100 -State "Error" -Overlay "warning"
        } finally {
            # Pool runspaces are reused, so leaving this set would make the next piece of
            # background work on this runspace believe it is a job worker
            $global:WinUtilIsJobWorker = $false

            Write-WinUtilTimingSummary -Scope $JobName -TotalMilliseconds $jobClock.ElapsedMilliseconds

            # A worker the watchdog cut off can reach here after the next job claimed the slot,
            # and everything below releases shared state.
            $stillOwns = $false
            [System.Threading.Monitor]::Enter($sync.SyncRoot)
            try {
                $stillOwns = $sync.ActiveJobToken -eq $JobToken
            } finally {
                [System.Threading.Monitor]::Exit($sync.SyncRoot)
            }

            if ($stillOwns) {
                if ($JobRestoresAppList -and (Test-WinUtilUIAlive)) {
                    Invoke-WPFUIThread -ScriptBlock {
                        if ($null -ne $sync.ItemsControl) { $sync.ItemsControl.IsEnabled = $true }
                    }
                }

                # Last, because the main thread may be waiting on it to know the run is over
                $null = Clear-WinUtilActiveJob -Token $JobToken
            } else {
                Write-WinUtilLog -Level "WARN" -Component $JobName -Message "$JobName unwound after another job had started; leaving its state alone."
            }
        }
    }
}

function Clear-WinUtilActiveJob {
    <#
        .SYNOPSIS
            Releases the active job slot, clearing its name and its token together

        .DESCRIPTION
            A token left set still matches a later run and blocks new work.

        .PARAMETER Token
            Release only if this run still owns the slot. Omit to release unconditionally.
    #>
    param([string]$Token)

    [System.Threading.Monitor]::Enter($sync.SyncRoot)
    try {
        if (-not $Token -or $sync.ActiveJobToken -eq $Token) {
            $sync.ActiveJobToken = $null
            $sync.ActiveJob = $null
            return $true
        }
        return $false
    } finally {
        [System.Threading.Monitor]::Exit($sync.SyncRoot)
    }
}
