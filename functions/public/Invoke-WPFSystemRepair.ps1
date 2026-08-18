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

    # SuccessCodes carries the non-zero exits a step treats as success. Only DISM has one:
    # 3010 is ERROR_SUCCESS_REBOOT_REQUIRED, meaning the image was repaired and the change
    # lands on restart. The same number from chkdsk or sfc does not mean that.
    $steps = @(
        @{ Label = "Checking the disk for errors";      Arguments = "/c chkdsk /scan /perf";                        SuccessCodes = @() },
        @{ Label = "Scanning protected system files";   Arguments = "/c sfc /scannow";                              SuccessCodes = @() },
        @{ Label = "Repairing the Windows image";       Arguments = "/c dism /online /cleanup-image /restorehealth"; SuccessCodes = @(3010) }
    )

    $completed = 0
    foreach ($step in $steps) {
        Step-WinUtilJob -Status "$($step.Label) ($($completed + 1)/$($steps.Count))" -Percent ([int](($completed / $steps.Count) * 100))
        Write-WinUtilLog -Component "SystemRepair" -Message $step.Label
        # Start-Process does not throw on a nonzero exit, so without this a failed chkdsk, sfc
        # or dism run would still be reported as a completed repair
        $process = Start-Process cmd.exe -ArgumentList $step.Arguments -NoNewWindow -Wait -PassThru
        $exitCode = $process.ExitCode

        if ($exitCode -eq 3010 -and $step.SuccessCodes -contains 3010) {
            Write-WinUtilLog -Level "WARN" -Component "SystemRepair" -Message "$($step.Label) finished; a restart is needed for the repair to take effect."
        } elseif ($exitCode -ne 0) {
            throw "$($step.Label) failed with exit code $exitCode."
        }

        $completed++
    }
}
