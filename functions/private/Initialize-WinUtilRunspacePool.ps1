function Initialize-WinUtilRunspacePool {
    if ($sync.runspace -and $sync.runspace.RunspacePoolStateInfo.State -eq [System.Management.Automation.Runspaces.RunspacePoolState]::Opened) {
        return $sync.runspace
    }

    if ($sync.runspace) {
        Close-WinUtilRunspacePool
    }

    # Set the maximum number of threads for the RunspacePool to the number of threads on the machine.
    $maxthreads = [Math]::Max([int]$env:NUMBER_OF_PROCESSORS, 1)

    # Create a new session state for parsing variables into our runspace.
    $hashVars = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'sync', $sync, $null
    $offlineVar = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'PARAM_OFFLINE', $PARAM_OFFLINE, $null
    $initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

    $initialSessionState.Variables.Add($hashVars)
    $initialSessionState.Variables.Add($offlineVar)

    # Get every WinUtil/WPF function and add it to the session state.
    $functions = Get-ChildItem function:\ | Where-Object { $_.Name -imatch 'winutil|WPF' }
    foreach ($function in $functions) {
        $functionDefinition = Get-Content function:\$($function.Name)
        $functionEntry = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $function.Name, $functionDefinition
        $initialSessionState.Commands.Add($functionEntry)
    }

    $sync.runspace = [runspacefactory]::CreateRunspacePool(
        1,                      # Minimum thread count
        $maxthreads,            # Maximum thread count
        $initialSessionState,   # Initial session state
        $Host                   # Machine to create runspaces on
    )

    $sync.runspace.Open()
    return $sync.runspace
}
