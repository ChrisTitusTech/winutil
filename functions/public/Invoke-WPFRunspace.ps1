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

    # Create a PowerShell instance
    $script:powershell = [powershell]::Create()

    # Add Scriptblock and Arguments to runspace
    $script:powershell.AddScript($ScriptBlock) | Out-Null
    if ($null -ne $ArgumentList) {
        $script:powershell.AddArgument($ArgumentList) | Out-Null
    }

    foreach ($parameter in $ParameterList) {
        $script:powershell.AddParameter($parameter[0], $parameter[1]) | Out-Null
    }

    $script:powershell.RunspacePool = $sync.runspace

    # Execute the RunspacePool
    $script:handle = $script:powershell.BeginInvoke()
    # Return both objects so callers that need blocking/cleanup can EndInvoke safely.
    return [PSCustomObject]@{
        PowerShell = $script:powershell
        Handle = $script:handle
    }
}
