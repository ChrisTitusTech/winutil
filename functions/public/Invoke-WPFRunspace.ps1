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

    $poolLock = Get-WinUtilRunspacePoolLock
    [System.Threading.Monitor]::Enter($poolLock)
    try {
        # The lifecycle lock keeps the final shutdown check, invocation start, and registration
        # atomic with pool closure. Otherwise shutdown can miss a newly started invocation.
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

        # Execute and register before allowing pool shutdown to take the lifecycle lock
        $handle = $powershell.BeginInvoke()
        Register-WinUtilActiveShell -PowerShell $powershell
        Register-WinUtilRunspaceCleanup -PowerShell $powershell -Handle $handle

        return $handle
    } finally {
        [System.Threading.Monitor]::Exit($poolLock)
    }
}
