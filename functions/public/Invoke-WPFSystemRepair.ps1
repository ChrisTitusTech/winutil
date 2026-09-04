function Invoke-WPFSystemRepair {
    <#
    .SYNOPSIS
        Checks for system corruption using SFC, and DISM
        Checks for disk failure using Chkdsk

    .DESCRIPTION
        1. Chkdsk - Checks for disk errors, which can cause system file corruption and notifies of early disk failure
        2. SFC - scans protected system files for corruption and fixes them
        3. DISM - Repair a corrupted Windows operating system image
    #>

    # SuccessCodes maps the non-zero exits a step treats as success to what they mean. The codes
    # are per step because the same number means different things: 1 and 2 are ordinary chkdsk
    # outcomes, while 1 from sfc is a failure, and 3010 is a repaired image from DISM only.
    $steps = @(
        @{
            Label = "Checking the disk for errors"
            Arguments = "/c chkdsk /scan /perf"
            # 3 is left out: the disk could not be checked, or has errors an online scan cannot
            # fix, and the steps after this one are not worth running on a disk in that state.
            SuccessCodes = @{
                1 = "errors were found and fixed"
                2 = "cleanup was performed, or was skipped because /f was not given"
            }
        },
        @{
            Label = "Scanning protected system files"
            Arguments = "/c sfc /scannow"
            SuccessCodes = @{}
        },
        @{
            Label = "Repairing the Windows image"
            Arguments = "/c dism /online /cleanup-image /restorehealth"
            SuccessCodes = @{
                3010 = "a restart is needed for the repair to take effect"
            }
        }
    )

    $completed = 0
    foreach ($step in $steps) {
        Step-WinUtilJob -Status "$($step.Label) ($($completed + 1)/$($steps.Count))" -Percent ([int](($completed / $steps.Count) * 100))
        Write-WinUtilLog -Component "SystemRepair" -Message $step.Label
        # Start-Process does not throw on a nonzero exit, so without this a failed chkdsk, sfc
        # or dism run would still be reported as a completed repair
        $process = Start-Process cmd.exe -ArgumentList $step.Arguments -NoNewWindow -Wait -PassThru
        $exitCode = $process.ExitCode

        if ($exitCode -ne 0) {
            if ($step.SuccessCodes.ContainsKey($exitCode)) {
                # Start-WinUtilJob records WarningRecord output in both the session log and the
                # job result, so accepted nonzero outcomes cannot finish with a green checkmark.
                Write-Warning "$($step.Label) finished: $($step.SuccessCodes[$exitCode])."
            } else {
                throw "$($step.Label) failed with exit code $exitCode."
            }
        }

        $completed++
    }
}
