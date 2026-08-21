function Complete-WinUtilPackageRun {
    <#
        .SYNOPSIS
            Reports what a package run actually did and fails the job if anything did not work

        .DESCRIPTION
            Package managers report failure through an exit code, which is easy to walk past.
            Without this the job layer would show a green checkmark for a run in which nothing
            installed. Throwing here is what turns a failed package into a failed job.

        .PARAMETER Action
            Install or Uninstall, used in the summary text.

    #>
    param(
        [Parameter(Mandatory)]
        [string]$Action,

        [object[]]$Results = @()
    )

    $succeeded = @($Results | Where-Object { $_.Outcome -eq "Succeeded" })
    $skipped = @($Results | Where-Object { $_.Outcome -eq "Skipped" })
    $failed = @($Results | Where-Object { $_.Outcome -eq "Failed" })

    $summary = "$($succeeded.Count) succeeded, $($skipped.Count) skipped, $($failed.Count) failed"
    Write-WinUtilLog -Component "Package" -Message "$Action summary: $summary"
    Write-Host "$Action summary: $summary"

    foreach ($result in $skipped) {
        Write-Host "  skipped  $($result.Package) - $($result.Detail)"
    }
    foreach ($result in $failed) {
        Write-Host "  failed   $($result.Package) - $($result.Detail)" -ForegroundColor Red
    }

    if ($failed.Count -gt 0) {
        $names = ($failed | ForEach-Object { $_.Package }) -join ', '
        $reasons = @($failed | ForEach-Object { $_.Detail } | Sort-Object -Unique)

        if ($reasons.Count -eq 1) {
            throw "$($failed.Count) of $($Results.Count) package(s) failed: $names. $($reasons[0])"
        }
        throw "$($failed.Count) of $($Results.Count) package(s) failed: $names. See the lines above for each reason."
    }
}
