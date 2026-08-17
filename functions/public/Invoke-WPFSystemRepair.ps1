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

    $steps = @(
        @{ Label = "Checking the disk for errors"; Arguments = "/c chkdsk /scan /perf" },
        @{ Label = "Scanning protected system files"; Arguments = "/c sfc /scannow" },
        @{ Label = "Repairing the Windows image"; Arguments = "/c dism /online /cleanup-image /restorehealth" }
    )

    $completed = 0
    foreach ($step in $steps) {
        Step-WinUtilJob -Status "$($step.Label) ($($completed + 1)/$($steps.Count))" -Percent ([int](($completed / $steps.Count) * 100))
        Write-WinUtilLog -Component "SystemRepair" -Message $step.Label
        Start-Process cmd.exe -ArgumentList $step.Arguments -NoNewWindow -Wait
        $completed++
    }
}
