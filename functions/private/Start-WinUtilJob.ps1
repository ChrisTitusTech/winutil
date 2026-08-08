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

            The body only has to do the work and call Write-WinUtilJobProgress. It must not
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
                Write-WinUtilJobProgress -Status "Installing" -Percent 10
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

    if ($sync.ActiveJob) {
        Show-WinUtilMessage -Message "$($sync.ActiveJob) is still running. Wait for it to finish before starting another action." -Title "WinUtil" -Button "OK" -Icon "Warning" | Out-Null
        return $null
    }

    $sync.ActiveJob = $Name

    $label = if ($Description) { $Description } else { $Name }
    Write-WinUtilLog -Component $Name -Message "$Name job started."
    Write-WinUtilJobBanner -Message $label
    Write-WinUtilJobProgress -Status "$label..." -Percent 0 -State "Normal" -Overlay "logo"

    if ($DisableAppList -and $sync.Form -and $sync.Form.Dispatcher) {
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
        ("JobRestoresAppList", [bool]$DisableAppList)
    ) -ScriptBlock {
        param($JobName, $JobLabel, $JobBody, $JobParameters, $JobRestoresAppList)

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

            # A step can fail without throwing, for example a registry write refused by policy.
            # The job still finished, but saying so without qualification would be a lie.
            $newErrors = if ($sync.LoggedErrors) { $sync.LoggedErrors.Count - $errorsBefore } else { 0 }
            if ($newErrors -gt 0) {
                Write-WinUtilLog -Level "WARN" -Component $JobName -Message "$JobName job finished in $($jobClock.ElapsedMilliseconds) ms with $newErrors error(s)."
                Write-WinUtilJobBanner -Message "$JobLabel finished with $newErrors error(s), see the log" -Level "ERROR"
                Write-WinUtilJobProgress -Status "$JobName finished with $newErrors error(s)" -Percent 100 -State "Paused" -Overlay "warning"
            } else {
                Write-WinUtilLog -Component $JobName -Message "$JobName job finished in $($jobClock.ElapsedMilliseconds) ms."
                Write-WinUtilJobBanner -Message "$JobLabel finished"
                Write-WinUtilJobProgress -Status "$JobName finished" -Percent 100 -State "None" -Overlay "checkmark"
            }
        } catch {
            $jobClock.Stop()
            Write-WinUtilErrorRecord -ErrorRecord $_ -Component $JobName -Context "$JobName failed after $($jobClock.ElapsedMilliseconds) ms"
            Write-WinUtilJobBanner -Message "$JobLabel failed: $($_.Exception.Message)" -Level "ERROR"
            Write-WinUtilJobProgress -Status "$JobName failed" -Percent 100 -State "Error" -Overlay "warning"
        } finally {
            Write-WinUtilTimingSummary -Scope $JobName -TotalMilliseconds $jobClock.ElapsedMilliseconds

            if ($JobRestoresAppList -and $sync.Form -and $sync.Form.Dispatcher) {
                Invoke-WPFUIThread -ScriptBlock {
                    if ($null -ne $sync.ItemsControl) { $sync.ItemsControl.IsEnabled = $true }
                }
            }

            $sync.ActiveJob = $null
        }
    }
}
