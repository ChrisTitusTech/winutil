function Complete-WinUtilRunspaceJobs {
    if (-not $sync.RunspaceJobs -or $sync.RunspaceJobs.Count -eq 0) {
        return
    }

    if (-not $sync.RunspaceJobsLock) {
        $sync.RunspaceJobsLock = [object]::new()
    }

    [System.Threading.Monitor]::Enter($sync.RunspaceJobsLock)
    try {
        $completed = @($sync.RunspaceJobs | Where-Object { $_.Handle.IsCompleted })
        foreach ($job in $completed) {
            try {
                $null = $job.PowerShell.EndInvoke($job.Handle)
            } catch {
                Write-Warning $_.Exception.Message
            } finally {
                $job.PowerShell.Dispose()
                $null = $sync.RunspaceJobs.Remove($job)
            }
        }
    } finally {
        [System.Threading.Monitor]::Exit($sync.RunspaceJobsLock)
    }
}

function Invoke-WPFRunspace {

    <#

    .SYNOPSIS
        Creates and invokes a runspace using the given scriptblock and argumentlist

    .PARAMETER ScriptBlock
        The scriptblock to invoke in the runspace

    .PARAMETER ArgumentList
        A list of arguments to pass to the runspace

    .PARAMETER ParameterList
        A list of named parameters that should be provided.
    .EXAMPLE
        Invoke-WPFRunspace `
            -ScriptBlock $sync.ScriptsInstallPrograms `
            -ArgumentList "Installadvancedip,Installbitwarden" `

        Invoke-WPFRunspace`
            -ScriptBlock $sync.ScriptsInstallPrograms `
            -ParameterList @(("PackagesToInstall", @("Installadvancedip,Installbitwarden")),("ChocoPreference", $true))
    #>

    [CmdletBinding()]
    Param (
        $ScriptBlock,
        $ArgumentList,
        $ParameterList
    )

    Complete-WinUtilRunspaceJobs

    if (-not $sync.RunspaceJobs) {
        $sync.RunspaceJobs = [System.Collections.Generic.List[hashtable]]::new()
    }

    if (-not $sync.RunspaceJobsLock) {
        $sync.RunspaceJobsLock = [object]::new()
    }

    $powershell = [powershell]::Create()

    $powershell.AddScript($ScriptBlock)
    if ($null -ne $ArgumentList) {
        $powershell.AddArgument($ArgumentList)
    }

    if ($ParameterList) {
        foreach ($parameter in $ParameterList) {
            $powershell.AddParameter($parameter[0], $parameter[1])
        }
    }

    $powershell.RunspacePool = $sync.runspace

    $handle = $powershell.BeginInvoke()

    $job = @{
        PowerShell = $powershell
        Handle = $handle
    }

    [System.Threading.Monitor]::Enter($sync.RunspaceJobsLock)
    try {
        if ($handle.IsCompleted) {
            try {
                $null = $job.PowerShell.EndInvoke($job.Handle)
            } catch {
                Write-Warning $_.Exception.Message
            } finally {
                $job.PowerShell.Dispose()
            }
        } else {
            $sync.RunspaceJobs.Add($job) | Out-Null
        }
    } finally {
        [System.Threading.Monitor]::Exit($sync.RunspaceJobsLock)
    }

    return $handle
}
