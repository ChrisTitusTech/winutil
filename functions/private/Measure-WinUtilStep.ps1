function Measure-WinUtilStep {
    <#
        .SYNOPSIS
            Times one step of a pipeline and records it for the timing summary

        .DESCRIPTION
            Output passes through untouched, so this can wrap an existing expression without
            changing what the caller receives. Each step is logged as a "timing:" line and kept
            in $sync.StepTimings for the summary to rank.

        .PARAMETER Name
            What the step is, as it should read in the log.

        .PARAMETER ScriptBlock
            The work to time.

        .PARAMETER Scope
            Groups steps that belong to the same run, normally a job name or "UI".
    #>
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory, Position = 1)]
        [scriptblock]$ScriptBlock,

        [string]$Scope = "WinUtil"
    )

    $isUIDiagnostic = $Scope -in @("UI", "Tab")
    $captureTiming = -not $isUIDiagnostic -or $sync.IsLocalCompile
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $ScriptBlock
    } finally {
        $stopwatch.Stop()

        if ($captureTiming -and $null -ne $sync.StepTimings) {
            $null = $sync.StepTimings.Add([pscustomobject]@{
                Scope = $Scope
                Step = $Name
                Milliseconds = $stopwatch.ElapsedMilliseconds
            })
        }

        if ($captureTiming) {
            $level = if ($isUIDiagnostic) { "DEBUG" } else { "INFO" }
            Write-WinUtilLog -Level $level -Component $Scope -Message "timing: $Name took $($stopwatch.ElapsedMilliseconds) ms"
        }
    }
}

function Write-WinUtilTimingSummary {
    <#
        .SYNOPSIS
            Logs the slowest steps of a scope, so the log answers "what took so long"

        .PARAMETER Scope
            Which group of steps to report on.

        .PARAMETER Top
            How many of the slowest steps to list.

        .PARAMETER TotalMilliseconds
            Wall clock total. Without it the summary sums the steps, missing whatever happened
            between them.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Scope,

        [int]$Top = 5,

        [long]$TotalMilliseconds = -1,

        [int]$StartIndex = 0
    )

    $isUIDiagnostic = $Scope -in @("UI", "Tab")
    if (($isUIDiagnostic -and -not $sync.IsLocalCompile) -or $null -eq $sync.StepTimings) {
        return
    }

    [System.Threading.Monitor]::Enter($sync.StepTimings.SyncRoot)
    try {
        $timingSnapshot = @($sync.StepTimings.ToArray())
    } finally {
        [System.Threading.Monitor]::Exit($sync.StepTimings.SyncRoot)
    }

    $steps = @($timingSnapshot | Select-Object -Skip $StartIndex | Where-Object { $_.Scope -eq $Scope })
    if ($steps.Count -eq 0) {
        return
    }

    $measured = ($steps | Measure-Object -Property Milliseconds -Sum).Sum
    $total = if ($TotalMilliseconds -ge 0) { $TotalMilliseconds } else { $measured }

    $level = if ($isUIDiagnostic) { "DEBUG" } else { "INFO" }
    Write-WinUtilLog -Level $level -Component $Scope -Message "timing summary: $($steps.Count) step(s), $measured ms measured of $total ms total"
    foreach ($step in ($steps | Sort-Object Milliseconds -Descending | Select-Object -First $Top)) {
        $share = if ($total -gt 0) { [int](($step.Milliseconds / $total) * 100) } else { 0 }
        Write-WinUtilLog -Level $level -Component $Scope -Message "timing summary:   $($step.Milliseconds) ms ($share%)  $($step.Step)"
    }
}
