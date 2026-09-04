function New-WinUtilSessionState {
    <#
        .SYNOPSIS
            Builds the InitialSessionState every WinUtil runspace is created from

        .DESCRIPTION
            The interface runspace and the worker pool start from the same state: the shared
            $sync hashtable, the compiled script's globals, and every WinUtil function. That is
            what lets the interface build a tab and a job body call any helper without injecting
            definitions by hand. PowerShell's own functions are skipped, the default session
            state already carries them.

            Cached: an InitialSessionState is a template any number of runspaces are created
            from, and building it is not free.
    #>

    if ($sync.SessionState) {
        return $sync.SessionState
    }

    $initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

    $variables = @(
        @{ Name = "sync"; Value = $sync },
        @{ Name = "PARAM_OFFLINE"; Value = $PARAM_OFFLINE },
        @{ Name = "inputXML"; Value = $inputXML },
        @{ Name = "WinUtilAutounattendXml"; Value = $WinUtilAutounattendXml }
    )

    foreach ($variable in $variables) {
        $initialSessionState.Variables.Add(
            (New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $variable.Name, $variable.Value, $null)
        )
    }

    $builtInFunctions = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]@($initialSessionState.Commands |
            Where-Object { $_ -is [System.Management.Automation.Runspaces.SessionStateFunctionEntry] } |
            ForEach-Object { $_.Name }),
        [StringComparer]::OrdinalIgnoreCase
    )

    foreach ($function in (Get-ChildItem function:\)) {
        if ($builtInFunctions.Contains($function.Name)) {
            continue
        }

        $initialSessionState.Commands.Add(
            (New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $function.Name, $function.Definition)
        )
    }

    $sync.SessionState = $initialSessionState
    return $initialSessionState
}
