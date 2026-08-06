function Measure-WinUtilStep {
    <#
        .SYNOPSIS
            Times one step of a pipeline and records it for the timing summary

        .DESCRIPTION
            Wrap any step whose cost is worth knowing. The step's own output passes through
            untouched, so this can be dropped around an existing expression without changing
            what the caller receives.

            Every recorded step reaches the session log as a "timing:" line and is kept in
            $sync.StepTimings so the summary can rank them afterwards.

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

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $ScriptBlock
    } finally {
        $stopwatch.Stop()

        if ($null -ne $sync.StepTimings) {
            $null = $sync.StepTimings.Add([pscustomobject]@{
                Scope = $Scope
                Step = $Name
                Milliseconds = $stopwatch.ElapsedMilliseconds
            })
        }

        Write-WinUtilLog -Component $Scope -Message "timing: $Name took $($stopwatch.ElapsedMilliseconds) ms"
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
            The measured wall-clock total. Without it the summary adds the steps up, which
            misses whatever happened between them.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Scope,

        [int]$Top = 5,

        [long]$TotalMilliseconds = -1
    )

    $steps = @($sync.StepTimings | Where-Object { $_.Scope -eq $Scope })
    if ($steps.Count -eq 0) {
        return
    }

    $measured = ($steps | Measure-Object -Property Milliseconds -Sum).Sum
    $total = if ($TotalMilliseconds -ge 0) { $TotalMilliseconds } else { $measured }

    Write-WinUtilLog -Component $Scope -Message "timing summary: $($steps.Count) step(s), $measured ms measured of $total ms total"
    foreach ($step in ($steps | Sort-Object Milliseconds -Descending | Select-Object -First $Top)) {
        $share = if ($total -gt 0) { [int](($step.Milliseconds / $total) * 100) } else { 0 }
        Write-WinUtilLog -Component $Scope -Message "timing summary:   $($step.Milliseconds) ms ($share%)  $($step.Step)"
    }
}
