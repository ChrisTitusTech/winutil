function Invoke-WPFRunspace {

    <#

    .SYNOPSIS
        Creates and invokes a runspace using the given scriptblock and argumentlist

    .PARAMETER ScriptBlock
        The scriptblock to invoke in the runspace

    .PARAMETER ArgumentList
        A list of arguments to pass to the runspace

    .EXAMPLE
        Invoke-WPFRunspace `
            -ScriptBlock $sync.ScriptsInstallPrograms `
            -ArgumentList "Installadvancedip,Installbitwarden" `

    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        [Parameter(Mandatory=$false)]
        [object[]]$ArgumentList,
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.ActionPreference]$DebugPreference = 'SilentlyContinue'
    )

    try {
        # Create a PowerShell instance
        $powershell = [powershell]::Create()

        # Add Scriptblock and Arguments to runspace
        $powershell.AddScript($ScriptBlock)
        if ($ArgumentList) {
            foreach ($Argument in $ArgumentList) {
                $powershell.AddArgument($Argument)
            }
        }
        $powershell.AddArgument($DebugPreference)

        # Ensure runspace pool is available
        if (-not $sync.runspace -or $sync.runspace.IsDisposed) {
            throw "Runspace pool is not initialized or has been disposed."
        }
        $powershell.RunspacePool = $sync.runspace

        # Execute the RunspacePool asynchronously
        $handle = $powershell.BeginInvoke()

        # Set up an event to handle completion
        $null = Register-ObjectEvent -InputObject $powershell -EventName InvocationStateChanged -Action {
            if ($EventArgs.InvocationStateInfo.State -eq "Completed") {
                $powershell.EndInvoke($handle)
                $powershell.Dispose()
                [System.GC]::Collect()
                Unregister-Event -SourceIdentifier $EventSubscriber.SourceIdentifier
            }
        }

        # Return the handle
        return $handle
    }
    catch {
        Write-Error "Error in Invoke-WPFRunspace: $_"
        if ($powershell) { $powershell.Dispose() }
        throw
    }
}
