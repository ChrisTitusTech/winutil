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

        .PARAMETER QueueIfBusy
            Waits in $sync.JobQueue for its turn instead of being refused, for actions the user
            starts. The parameters are held as they were when it was queued.

        .PARAMETER FromQueue
            Internal to Start-WinUtilNextQueuedJob: this is the queued job taking its turn, so it
            may claim the slot while $sync.JobHandoff holds it for the queue.

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

        [switch]$DisableAppList,

        [switch]$QueueIfBusy,

        [switch]$FromQueue
    )

    if ($sync.ShuttingDown -or $sync.FinishInConsole) {
        if ($FromQueue) { Reset-WinUtilJobHandoff }
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
    $queuePosition = 0
    [System.Threading.Monitor]::Enter($sync.SyncRoot)
    try {
        if ($FromQueue) {
            $sync.JobHandoff = $false
        }
        # A finished job's slot is promised to the queue until its head has started
        if ($sync.ActiveJob -or $sync.JobHandoff) {
            $blockedBy = if ($sync.ActiveJob) { $sync.ActiveJob } else { "Queued operations" }
            # In the same lock as the busy test: a job finishing between the two would leave
            # this one queued behind nothing
            if ($QueueIfBusy) {
                $sync.JobQueue.Add([pscustomobject]@{
                    Id = [guid]::NewGuid().ToString()
                    Name = $Name
                    Description = $Description
                    ScriptBlock = $ScriptBlock.ToString()
                    Parameters = $Parameters
                    DisableAppList = [bool]$DisableAppList
                })
                $queuePosition = $sync.JobQueue.Count
            }
        } else {
            $sync.ActiveJob = $Name
            $sync.ActiveJobToken = $jobToken
            $sync.LastJobResult = $null
        }
    } finally {
        [System.Threading.Monitor]::Exit($sync.SyncRoot)
    }

    if ($queuePosition -gt 0) {
        Write-WinUtilLog -Component $Name -Message "$Name queued behind $blockedBy, position $queuePosition."
        Invoke-WPFUIThread -Async -ScriptBlock { Update-WinUtilJobQueueUI }
        return $null
    }

    if ($blockedBy) {
        Show-WinUtilMessage -Message "$blockedBy is still running. Wait for it to finish before starting another action." -Title "WinUtil" -Button "OK" -Icon "Warning" | Out-Null
        return $null
    }

    $label = if ($Description) { $Description } else { $Name }
    try {
        $timingStartIndex = if ($sync.StepTimings) { $sync.StepTimings.Count } else { 0 }

        Write-WinUtilLog -Component $Name -Message "$Name job started."
        Invoke-WPFUIThread -Async -ScriptBlock { Update-WinUtilJobQueueUI }
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
            ("JobToken", $jobToken),
            ("TimingStartIndex", $timingStartIndex)
        ) -ScriptBlock {
        param($JobName, $JobLabel, $JobBody, $JobParameters, $JobRestoresAppList, $JobToken, $TimingStartIndex)

        # Marks this runspace as the one doing the work, so a pause holds here and not in
        # whoever asked for it
        $global:WinUtilIsJobWorker = $true
        $global:WinUtilJobErrorCount = 0
        $global:WinUtilJobWarningCount = 0

        $jobClock = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $body = [scriptblock]::Create($JobBody)

            # A worker's warning and error streams buffer on a PowerShell object nobody reads.
            # Merging them into the output stream is what gets them to the log.
            & $body @JobParameters 2>&1 3>&1 | ForEach-Object {
                if ($_ -is [System.Management.Automation.WarningRecord]) {
                    $global:WinUtilJobWarningCount++
                    Write-WinUtilLog -Level "WARN" -Component $JobName -Message $_.Message
                } elseif ($_ -is [System.Management.Automation.ErrorRecord]) {
                    Write-WinUtilErrorRecord -ErrorRecord $_ -Component $JobName -Context "Non-terminating error"
                }
            }

            $jobClock.Stop()

            # A step can fail without throwing, for example a registry write refused by policy.
            # The counter belongs to this worker runspace, so unrelated UI errors cannot change
            # this job's result while it is running.
            $newErrors = $global:WinUtilJobErrorCount
            $newWarnings = $global:WinUtilJobWarningCount
            if ($newErrors -gt 0) {
                Write-WinUtilLog -Level "WARN" -Component $JobName -Message "$JobName job finished in $($jobClock.ElapsedMilliseconds) ms with $newErrors error(s)."
                Write-WinUtilJobBanner -Message "$JobLabel finished with $newErrors error(s), see the log" -Level "ERROR"
                Step-WinUtilJob -Status "$JobName finished with $newErrors error(s)" -Percent 100 -State "Paused" -Overlay "warning"
            } elseif ($newWarnings -gt 0) {
                Write-WinUtilLog -Level "WARN" -Component $JobName -Message "$JobName job finished in $($jobClock.ElapsedMilliseconds) ms with $newWarnings warning(s)."
                Write-WinUtilJobBanner -Message "$JobLabel finished with $newWarnings warning(s), see the log"
                Step-WinUtilJob -Status "$JobName finished with $newWarnings warning(s)" -Percent 100 -State "Paused" -Overlay "warning"
            } else {
                Write-WinUtilLog -Component $JobName -Message "$JobName job finished in $($jobClock.ElapsedMilliseconds) ms."
                Write-WinUtilJobBanner -Message "$JobLabel finished"
                Step-WinUtilJob -Status "$JobName finished" -Percent 100 -State "None" -Overlay "checkmark"
            }
        } catch {
            $jobClock.Stop()
            # A leaf that logs before rethrowing marks that exact exception. Preserve the outer
            # context and stack without counting it twice; unrelated earlier errors do not qualify.
            $errorAlreadyReported = $_.Exception.Data["WinUtilErrorReported"] -eq $true
            Write-WinUtilErrorRecord -ErrorRecord $_ -Component $JobName -Context "$JobName failed after $($jobClock.ElapsedMilliseconds) ms" -DetailOnly:$errorAlreadyReported
            Write-WinUtilJobBanner -Message "$JobLabel failed: $($_.Exception.Message)" -Level "ERROR"
            Step-WinUtilJob -Status "$JobName failed" -Percent 100 -State "Error" -Overlay "warning"
        } finally {
            $jobResult = [pscustomobject]@{
                Token = $JobToken
                Errors = $global:WinUtilJobErrorCount
                Warnings = $global:WinUtilJobWarningCount
            }

            # Pool runspaces are reused, so leaving this set would make the next piece of
            # background work on this runspace believe it is a job worker
            $global:WinUtilIsJobWorker = $false
            $global:WinUtilJobErrorCount = 0
            $global:WinUtilJobWarningCount = 0

            Write-WinUtilTimingSummary -Scope $JobName -TotalMilliseconds $jobClock.ElapsedMilliseconds -StartIndex $TimingStartIndex

            # A worker the watchdog cut off can reach here after the next job claimed the slot,
            # and everything below releases shared state.
            $stillOwns = $false
            [System.Threading.Monitor]::Enter($sync.SyncRoot)
            try {
                $stillOwns = $sync.ActiveJobToken -eq $JobToken
                if ($stillOwns) {
                    $sync.LastJobResult = $jobResult
                }
            } finally {
                [System.Threading.Monitor]::Exit($sync.SyncRoot)
            }

            if ($stillOwns) {
                try {
                    if ($JobRestoresAppList -and (Test-WinUtilUIAlive)) {
                        Invoke-WPFUIThread -ScriptBlock {
                            if ($null -ne $sync.ItemsControl) { $sync.ItemsControl.IsEnabled = $true }
                        }
                    }
                } catch {
                    Write-WinUtilLog -Level "WARN" -Component $JobName -Message "Could not restore the app list after $JobName finished: $($_.Exception.Message)"
                } finally {
                    # Dispatcher shutdown can race the alive check and abort the restore call.
                    # The worker is still finished, so its slot must always be released.
                    $null = Clear-WinUtilActiveJob -Token $JobToken
                }
            } else {
                Write-WinUtilLog -Level "WARN" -Component $JobName -Message "$JobName unwound after another job had started; leaving its state alone."
            }
        }
        }
    } catch {
        $scheduleError = $_
        try {
            Write-WinUtilErrorRecord -ErrorRecord $scheduleError -Component $Name -Context "Could not schedule $Name"
            $sync.LastJobResult = [pscustomobject]@{ Token = $jobToken; Errors = 1; Warnings = 0 }
            Write-WinUtilJobBanner -Message "$label could not start" -Level "ERROR"
            Step-WinUtilJob -Status "$Name could not start" -Percent 100 -State "Error" -Overlay "warning"
        } catch {
            Write-WinUtilLog -Level "WARN" -Component $Name -Message "Could not report that $Name failed to start: $($_.Exception.Message)"
        } finally {
            try {
                if ($DisableAppList -and (Test-WinUtilUIAlive)) {
                    Invoke-WPFUIThread -ScriptBlock {
                        if ($null -ne $sync.ItemsControl) { $sync.ItemsControl.IsEnabled = $true }
                    }
                }
            } catch {
                Write-WinUtilLog -Level "WARN" -Component $Name -Message "Could not restore the app list after $Name failed to start: $($_.Exception.Message)"
            } finally {
                $null = Clear-WinUtilActiveJob -Token $jobToken
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

    $released = $false
    [System.Threading.Monitor]::Enter($sync.SyncRoot)
    try {
        if (-not $Token -or $sync.ActiveJobToken -eq $Token) {
            $sync.ActiveJobToken = $null
            $sync.ActiveJob = $null
            $released = $true
            # Between here and the posted dispatch the slot is free, and a new action must not
            # take it ahead of the queue
            if ($Token -and $sync.JobQueue.Count -gt 0 -and -not $sync.ShuttingDown -and -not $sync.FinishInConsole) {
                $sync.JobHandoff = $true
            }
        }
    } finally {
        [System.Threading.Monitor]::Exit($sync.SyncRoot)
    }

    # A job that ended, however it ended, hands the slot to the next queued one. A release with no
    # token is a forced reset, which must not start anything.
    if ($released -and $Token) {
        try {
            Invoke-WPFUIThread -Async -ScriptBlock { Start-WinUtilNextQueuedJob }
        } catch {
            Reset-WinUtilJobHandoff
            Write-WinUtilLog -Level "WARN" -Component "UI" -Message "Could not start the next queued job: $($_.Exception.Message)"
        }
    }
    return $released
}
