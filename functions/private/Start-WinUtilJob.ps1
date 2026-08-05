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
              - a start, finish and failure line in the log under the job's own component
              - catching anything the body throws, so a failure cannot leave the UI stuck busy
              - restoring the interface in a finally block whatever happens

            The body only has to do the work and call Write-WinUtilJobProgress.

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
    # Kept in step with ActiveJob because existing code and tests read this flag
    $sync.ProcessRunning = $true

    $label = if ($Description) { $Description } else { $Name }
    Write-WinUtilLog -Component $Name -Message "$Name job started."
    Write-WinUtilJobProgress -Status "$label..." -Percent 0 -State "Normal" -Overlay "logo"

    if ($DisableAppList -and $sync.Form -and $sync.Form.Dispatcher) {
        Invoke-WPFUIThread -ScriptBlock {
            if ($null -ne $sync.ItemsControl) { $sync.ItemsControl.IsEnabled = $false }
        }
    }

    # The body is rebuilt inside the runspace from its text. A scriptblock carries the session
    # state it was defined in, and recreating it there keeps it bound to the worker instead.
    Invoke-WPFRunspace -ParameterList @(
        ("JobName", $Name),
        ("JobBody", $ScriptBlock.ToString()),
        ("JobParameters", $Parameters),
        ("JobRestoresAppList", [bool]$DisableAppList)
    ) -ScriptBlock {
        param($JobName, $JobBody, $JobParameters, $JobRestoresAppList)

        try {
            $body = [scriptblock]::Create($JobBody)
            & $body @JobParameters

            Write-WinUtilLog -Component $JobName -Message "$JobName job finished."
            Write-WinUtilJobProgress -Status "$JobName finished" -Percent 100 -State "None" -Overlay "checkmark"
        } catch {
            Write-WinUtilLog -Level "ERROR" -Component $JobName -Message "$JobName job failed: $($_.Exception.Message)"
            Write-Host "$JobName failed: $($_.Exception.Message)"
            Write-WinUtilJobProgress -Status "$JobName failed" -Percent 100 -State "Error" -Overlay "warning"
        } finally {
            if ($JobRestoresAppList -and $sync.Form -and $sync.Form.Dispatcher) {
                Invoke-WPFUIThread -ScriptBlock {
                    if ($null -ne $sync.ItemsControl) { $sync.ItemsControl.IsEnabled = $true }
                }
            }

            $sync.ProcessRunning = $false
            $sync.ActiveJob = $null
        }
    }
}
