function Start-WinUtilJob {
    <#
        .SYNOPSIS
            Runs a long operation off the UI thread with the shared progress, taskbar, log and
            error handling applied around it

        .DESCRIPTION
            Every long running WinUtil action goes through here instead of repeating the same
            ceremony. The job layer owns:

              - refusing to start while another job is running, with one consistent message
              - the busy flag other code checks
              - the progress bar and taskbar item for the whole lifetime of the job
              - the boxed start and finish banner in the console
              - a start, finish and failure line in the log under the job's own component
              - catching anything the body throws, so a failure cannot leave the UI stuck busy
              - restoring the interface in a finally block whatever happens

            The body only has to do the work and call Step-WinUtilJob. It must not
            print its own banner or set the busy flag.

        .PARAMETER Name
            Short job name. Used as the log component and in progress text, for example Install.

        .PARAMETER ScriptBlock
            The work to run. Receives the entries of Parameters as named parameters.

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

    # A job body that starts another job runs it inline. The outer job already owns the slot,
    # the banner and the reporting, so claiming again would refuse the inner call and skip the
    # work silently: that is what happened to the Install Features button, which reaches here
    # once through its feature.json entry and again from Invoke-WPFFeatureInstall.
    if ($global:WinUtilIsJobWorker) {
        & $ScriptBlock @Parameters
        return $null
    }

    # Claimed under the collection's own lock. Interface events are serialised by the dispatcher,
    # but a headless run, a scheduled caller or a job body starting another job are not, and a
    # plain test-then-assign there lets two jobs both believe they own the slot.
    #
    # The token identifies this run rather than its name, because a worker that was cut off can
    # still be unwinding when the next job starts, and releasing the slot by name would hand away
    # a claim that now belongs to that next job.
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

    # A pause or stop left from the previous run would hold or end this one before it started
    $sync.JobPaused = $false
    $sync.StopRequested = $false
    if (Test-WinUtilUIAlive) {
        Invoke-WPFUIThread -ScriptBlock {
            if ($sync.WPFPauseJobButton) {
                $sync.WPFPauseJobButton.Content = [string]([char]0xE769)
                $sync.WPFPauseJobButton.ToolTip = "Pause after the current step"
                $sync.WPFPauseJobButton.IsEnabled = $true
                $sync.WPFPauseJobButton.Visibility = "Visible"
            }
            if ($sync.WPFStopJobButton) {
                $sync.WPFStopJobButton.IsEnabled = $true
                $sync.WPFStopJobButton.Visibility = "Visible"
            }
        }
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

    # The body is rebuilt inside the runspace from its text. A scriptblock carries the session
    # state it was defined in, and recreating it there keeps it bound to the worker instead.
    # The handle is of no use to the caller, and printing it puts an IAsyncResult table on the
    # console every time a button is pressed
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

            # A worker's warning and error streams are buffered on a PowerShell object nobody
            # reads, so Write-Warning never reaches the log and Write-Error reaches nothing at
            # all. Merging them into the output stream is what puts them in front of a reader.
            & $body @JobParameters 2>&1 3>&1 | ForEach-Object {
                if ($_ -is [System.Management.Automation.WarningRecord]) {
                    Write-WinUtilLog -Level "WARN" -Component $JobName -Message $_.Message
                } elseif ($_ -is [System.Management.Automation.ErrorRecord]) {
                    Write-WinUtilErrorRecord -ErrorRecord $_ -Component $JobName -Context "Non-terminating error"
                }
            }

            $jobClock.Stop()

            # The body has returned, so there is nothing left to hold or to end. Without this the
            # finish reporting itself would pause, or throw the stop again from inside the
            # handler that is reporting it.
            $sync.JobPaused = $false
            $sync.StopRequested = $false

            # A step can fail without throwing, for example a registry write refused by policy.
            # The job still finished, but saying so without qualification would be a lie.
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
        } catch [System.OperationCanceledException] {
            # Asked to stop rather than gone wrong, so it is not reported as a failure
            $jobClock.Stop()
            $sync.JobPaused = $false
            $sync.StopRequested = $false
            Write-WinUtilLog -Level "WARN" -Component $JobName -Message "$JobName stopped after $($jobClock.ElapsedMilliseconds) ms at the user's request."
            Write-WinUtilJobBanner -Message "$JobLabel stopped"
            Step-WinUtilJob -Status "$JobName stopped" -Percent 100 -State "Paused" -Overlay "warning"
        } catch {
            $jobClock.Stop()
            $sync.JobPaused = $false
            $sync.StopRequested = $false
            Write-WinUtilErrorRecord -ErrorRecord $_ -Component $JobName -Context "$JobName failed after $($jobClock.ElapsedMilliseconds) ms"
            Write-WinUtilJobBanner -Message "$JobLabel failed: $($_.Exception.Message)" -Level "ERROR"
            Step-WinUtilJob -Status "$JobName failed" -Percent 100 -State "Error" -Overlay "warning"
        } finally {
            # Pool runspaces are reused, so leaving this set would make the next piece of
            # background work on this runspace believe it is a job worker
            $global:WinUtilIsJobWorker = $false

            Write-WinUtilTimingSummary -Scope $JobName -TotalMilliseconds $jobClock.ElapsedMilliseconds

            # Whether this run still owns the slot. A worker the watchdog cut off can reach here
            # long after the next job has claimed it, and everything below releases shared state.
            $stillOwns = $false
            [System.Threading.Monitor]::Enter($sync.SyncRoot)
            try {
                $stillOwns = $sync.ActiveJobToken -eq $JobToken
            } finally {
                [System.Threading.Monitor]::Exit($sync.SyncRoot)
            }

            if ($stillOwns) {
                # Nothing left to pause once the run is over
                $sync.JobPaused = $false
                # Hidden rather than just disabled: the progress bar stays to report how the run
                # ended, but there is nothing left for these two to act on
                Invoke-WPFUIThread -ScriptBlock {
                    if ($sync.WPFPauseJobButton) {
                        $sync.WPFPauseJobButton.IsEnabled = $false
                        $sync.WPFPauseJobButton.Visibility = "Collapsed"
                    }
                    if ($sync.WPFStopJobButton) {
                        $sync.WPFStopJobButton.IsEnabled = $false
                        $sync.WPFStopJobButton.Visibility = "Collapsed"
                    }
                }

                if ($JobRestoresAppList -and (Test-WinUtilUIAlive)) {
                    Invoke-WPFUIThread -ScriptBlock {
                        if ($null -ne $sync.ItemsControl) { $sync.ItemsControl.IsEnabled = $true }
                    }
                }

                # Last thing done, because the main thread may be waiting on exactly this to know
                # the run is over and the process can exit
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
            Clearing the name alone leaves the token set, where it can still match a later run
            and keep the job layer from accepting work. Every release goes through here.

        .PARAMETER Token
            Release only if this run still owns the slot. Omit to release whatever holds it.
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
