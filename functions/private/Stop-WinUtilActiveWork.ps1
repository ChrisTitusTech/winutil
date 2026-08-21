function Test-WinUtilShellRunning {
    <#
        .SYNOPSIS
            Whether one instance is still running, treating a disposed one as finished
    #>
    param($PowerShell)

    try {
        return $PowerShell.InvocationStateInfo.State -eq [System.Management.Automation.PSInvocationState]::Running
    } catch {
        return $false
    }
}

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

    # Synchronized protects one operation, not a test followed by an assignment, so the
    # collection is created under the shared lock
    [System.Threading.Monitor]::Enter($sync.SyncRoot)
    try {
        if ($null -eq $sync.ActiveShells) {
            $sync.ActiveShells = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
        }
    } finally {
        [System.Threading.Monitor]::Exit($sync.SyncRoot)
    }

    # Nothing disposes these on the way out, so finished ones are dropped here instead of
    # accumulating for the life of the session
    foreach ($finished in (Get-WinUtilActiveShell)) {
        if (-not (Test-WinUtilShellRunning $finished)) {
            try { $sync.ActiveShells.Remove($finished) } catch { }
        }
    }

    $null = $sync.ActiveShells.Add($PowerShell)
}

function Get-WinUtilActiveShell {
    <#
        .SYNOPSIS
            A snapshot of the tracked instances, copied under the collection's own lock

        .DESCRIPTION
            Enumerating a synchronized ArrayList is not itself synchronized, so a concurrent Add
            or Remove throws mid-loop. Copying under SyncRoot is what the type documents.
    #>

    if ($null -eq $sync.ActiveShells) {
        return @()
    }

    [System.Threading.Monitor]::Enter($sync.ActiveShells.SyncRoot)
    try {
        return @($sync.ActiveShells.ToArray())
    } finally {
        [System.Threading.Monitor]::Exit($sync.ActiveShells.SyncRoot)
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
        [int]$TimeoutSeconds = 15,

        # Issue the stop and return. The caller polls Test-WinUtilActiveWorkRunning instead of
        # blocking here, which matters on the interface thread where a wait freezes the window.
        [switch]$NoWait
    )

    $shells = Get-WinUtilActiveShell
    if ($shells.Count -eq 0) {
        return $true
    }

    Write-WinUtilLog -Component "UI" -Message "Stopping $($shells.Count) running item(s) before closing."

    foreach ($shell in $shells) {
        if (Test-WinUtilShellRunning $shell) {
            try { $null = $shell.BeginStop($null, $null) } catch { }
        }
    }

    if ($NoWait) {
        return $false
    }

    $clock = [System.Diagnostics.Stopwatch]::StartNew()
    while ($clock.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        $stillRunning = @(Get-WinUtilActiveShell | Where-Object { Test-WinUtilShellRunning $_ }).Count

        if ($stillRunning -eq 0) {
            Write-WinUtilLog -Component "UI" -Message "Everything stopped after $($clock.ElapsedMilliseconds) ms."
            return $true
        }

        Start-Sleep -Milliseconds 100
    }

    Write-WinUtilLog -Level "WARN" -Component "UI" -Message "Gave up waiting for work to stop after $TimeoutSeconds seconds, closing anyway."
    return $false
}

function Test-WinUtilActiveWorkRunning {
    <#
        .SYNOPSIS
            Whether any tracked instance is still running
    #>

    foreach ($shell in (Get-WinUtilActiveShell)) {
        if (Test-WinUtilShellRunning $shell) { return $true }
    }

    return $false
}
