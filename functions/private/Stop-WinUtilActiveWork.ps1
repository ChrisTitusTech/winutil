function Register-WinUtilActiveShell {
    <#
        .SYNOPSIS
            Records a PowerShell instance that is running on the worker pool

        .DESCRIPTION
            Closing the pool while an instance is still queued leaves that instance to start on a
            runspace that is already closing. It throws there, on a thread pool thread, where
            nothing is catching, and the process is taken down with it. Knowing what is in flight
            is what makes it possible to stop them first.
    #>
    param(
        [Parameter(Mandatory)]
        $PowerShell
    )

    if ($null -eq $sync.ActiveShells) {
        $sync.ActiveShells = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
    }

    # Instances are disposed by a callback that cannot reach here, so finished ones are dropped
    # on the way past rather than accumulating for the life of the session
    foreach ($finished in @($sync.ActiveShells)) {
        $done = $true
        try {
            $done = $finished.InvocationStateInfo.State -ne [System.Management.Automation.PSInvocationState]::Running
        } catch {
            # disposed, which is as finished as it gets
        }
        if ($done) {
            Unregister-WinUtilActiveShell -PowerShell $finished
        }
    }

    $null = $sync.ActiveShells.Add($PowerShell)
}

function Unregister-WinUtilActiveShell {
    <#
        .SYNOPSIS
            Forgets an instance that has finished
    #>
    param(
        [Parameter(Mandatory)]
        $PowerShell
    )

    if ($null -eq $sync.ActiveShells) {
        return
    }

    try {
        $sync.ActiveShells.Remove($PowerShell)
    } catch {
        # A collection changed underneath is not worth failing a completed job over
    }
}

function Stop-WinUtilActiveWork {
    <#
        .SYNOPSIS
            Asks everything running on the worker pool to stop, and waits for it

        .DESCRIPTION
            Stop is a request rather than a kill: a command already inside an installer keeps
            going until that command returns. The wait is bounded so a worker that never comes
            back cannot keep the window open for ever.

        .PARAMETER TimeoutSeconds
            How long to wait for the work to end before giving up on it.
    #>
    param(
        [int]$TimeoutSeconds = 15
    )

    # @($null) is a one element array holding null, not an empty one, so the absence of the
    # collection has to be checked before wrapping it
    $shells = if ($sync.ActiveShells) { @($sync.ActiveShells) } else { @() }
    if ($shells.Count -eq 0) {
        return $true
    }

    Write-WinUtilLog -Component "UI" -Message "Stopping $($shells.Count) running item(s) before closing."

    foreach ($shell in $shells) {
        try {
            if ($shell.InvocationStateInfo.State -eq [System.Management.Automation.PSInvocationState]::Running) {
                $null = $shell.BeginStop($null, $null)
            }
        } catch {
            # Already finished or disposed; either way there is nothing left to stop
        }
    }

    $clock = [System.Diagnostics.Stopwatch]::StartNew()
    while ($clock.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        $stillRunning = 0
        foreach ($shell in $(if ($sync.ActiveShells) { @($sync.ActiveShells) } else { @() })) {
            try {
                if ($shell.InvocationStateInfo.State -eq [System.Management.Automation.PSInvocationState]::Running) {
                    $stillRunning++
                }
            } catch {
                # disposed while we looked at it, which means it is done
            }
        }

        if ($stillRunning -eq 0) {
            Write-WinUtilLog -Component "UI" -Message "Everything stopped after $($clock.ElapsedMilliseconds) ms."
            return $true
        }

        Start-Sleep -Milliseconds 100
    }

    Write-WinUtilLog -Level "WARN" -Component "UI" -Message "Gave up waiting for work to stop after $TimeoutSeconds seconds, closing anyway."
    return $false
}
