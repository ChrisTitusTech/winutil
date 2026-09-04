function Write-WinUtilErrorRecord {
    <#
        .SYNOPSIS
            Logs a failure with enough context to act on it

        .DESCRIPTION
            A bare "You cannot call a method on a null-valued expression." says nothing about
            where it came from. This records the message together with the exception type, the
            command and line that raised it, and the script stack, under a component name.

        .PARAMETER ErrorRecord
            The error to report, normally $_ from a catch block.

        .PARAMETER Component
            Which part of WinUtil was running, for example Install or UI.

        .PARAMETER Context
            What was being attempted, for example the button name or the package.
    #>
    param(
        [Parameter(Mandatory)]
        $ErrorRecord,

        [string]$Component = "WinUtil",

        [string]$Context,

        # The underlying failure was already logged and counted; retain this call's context and
        # stack as diagnostic detail without adding a second headline error.
        [switch]$DetailOnly
    )

    $headline = if ($Context) { "$Context : $($ErrorRecord.Exception.Message)" } else { $ErrorRecord.Exception.Message }
    Write-WinUtilLog -Level "ERROR" -Component $Component -Message $headline -Detail:$DetailOnly

    $invocation = $ErrorRecord.InvocationInfo
    if ($invocation) {
        $where = "$($invocation.ScriptName):$($invocation.ScriptLineNumber)"
        if ([string]::IsNullOrWhiteSpace($invocation.ScriptName)) {
            $where = "line $($invocation.ScriptLineNumber)"
        }
        Write-WinUtilLog -Level "ERROR" -Detail -Component $Component -Message "  at $where in $($invocation.MyCommand): $($invocation.Line.Trim())"
    }

    Write-WinUtilLog -Level "ERROR" -Detail -Component $Component -Message "  type $($ErrorRecord.Exception.GetType().FullName), category $($ErrorRecord.CategoryInfo.Category)"

    if ($ErrorRecord.ScriptStackTrace) {
        foreach ($frame in ($ErrorRecord.ScriptStackTrace -split "`r?`n")) {
            if (-not [string]::IsNullOrWhiteSpace($frame)) {
                Write-WinUtilLog -Level "ERROR" -Detail -Component $Component -Message "  $($frame.Trim())"
            }
        }
    }

    if (-not $DetailOnly) {
        Write-Host "$Component : $headline" -ForegroundColor Red
    }
}
