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
        $ScriptBlock,
        $ArgumentList,
        $DebugPreference
    )

    # Create a PowerShell instance
    $script:powershell = [powershell]::Create()

    # Add Scriptblock and Arguments to runspace
    $script:powershell.AddScript($ScriptBlock)
    $script:powershell.AddArgument($ArgumentList)
    $script:powershell.AddArgument($DebugPreference)  # Pass DebugPreference to the script block
    $script:powershell.RunspacePool = $sync.runspace

    # Execute the RunspacePool
    $script:handle = $script:powershell.BeginInvoke()

    # Clean up the RunspacePool threads when they are complete, and invoke the garbage collector to clean up the memory
    if ($script:handle.IsCompleted)
    {
        $script:powershell.EndInvoke($script:handle)
        $script:powershell.Dispose()
        $sync.runspace.Dispose()
        $sync.runspace.Close()
        [System.GC]::Collect()
    }
}