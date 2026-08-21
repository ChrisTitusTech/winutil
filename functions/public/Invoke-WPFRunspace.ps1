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
    [OutputType([System.IAsyncResult])]
    Param (
        $ScriptBlock,
        $ArgumentList,
        $ParameterList
    )

    # Starting work into a pool that is closing gives that instance a runspace it can never run
    # on, and it throws on a thread pool thread where nothing is catching
    if ($sync.ShuttingDown) {
        Write-WinUtilLog -Level "WARN" -Component "UI" -Message "Refused to start background work, WinUtil is closing."
        return $null
    }

    Initialize-WinUtilRunspacePool | Out-Null

    # Create a PowerShell instance
    $powershell = [powershell]::Create()

    # Add Scriptblock and Arguments to runspace
    [void]$powershell.AddScript($ScriptBlock)
    [void]$powershell.AddArgument($ArgumentList)

    foreach ($parameter in $ParameterList) {
        # A single pair written as @(("Name", $value)) collapses to a two element array, and
        # indexing it then yields the first two characters of the name
        if ($parameter -is [string] -or $parameter.Count -ne 2) {
            throw "ParameterList takes name and value pairs. Received '$parameter'. A single pair needs a leading comma: -ParameterList (,('Name', `$value))"
        }
        [void]$powershell.AddParameter($parameter[0], $parameter[1])
    }

    $powershell.RunspacePool = $sync.runspace

    # Execute the RunspacePool
    $handle = $powershell.BeginInvoke()

    # Registered after the invocation starts: a NotStarted instance is indistinguishable from a
    # finished one to the pruning pass, which would drop it and hide its work from shutdown
    Register-WinUtilActiveShell -PowerShell $powershell

    Register-WinUtilRunspaceCleanup -PowerShell $powershell -Handle $handle

    # Return the handle
    return $handle
}
