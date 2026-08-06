function New-WinUtilSessionState {
    <#
        .SYNOPSIS
            Builds the InitialSessionState every WinUtil runspace is created from

        .DESCRIPTION
            Both the interface runspace and the worker pool need the same starting point: the
            shared $sync hashtable, the compiled script's globals, and every function WinUtil
            defines. That completeness is what lets the interface build a tab and a job body
            call any helper without the caller injecting function definitions by hand.

            Only the functions PowerShell itself provides are skipped, since the default
            session state already carries those.
    #>

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

    return $initialSessionState
}
