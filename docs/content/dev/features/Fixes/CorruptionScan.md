---
title: "System Corruption Scan"
description: ""
---
```powershell
function Invoke-WPFSystemRepair {
    <#
    .SYNOPSIS
        Checks for system corruption using Chkdsk, SFC, and DISM

    .DESCRIPTION
        1. Chkdsk    - Fixes disk and filesystem corruption
        2. SFC Run 1 - Fixes system file corruption, and fixes DISM if it was corrupted
        3. DISM      - Fixes system image corruption, and fixes SFC's system image if it was corrupted
        4. SFC Run 2 - Fixes system file corruption, this time with an almost guaranteed uncorrupted system image
    #>

    function Invoke-Chkdsk {
        <#
        .SYNOPSIS
            Runs chkdsk on the system drive
        .DESCRIPTION
            Chkdsk /Scan - Runs an online scan on the system drive, attempts to fix any corruption, and queues other corruption for fixing on reboot
        #>
        param(
            [int]$parentProgressId = 0
        )

        Write-Progress -Id 1 -ParentId $parentProgressId -Activity $childProgressBarActivity -Status "Running chkdsk..." -PercentComplete 0
        $oldpercent = 0
        # 2>&1 redirects stdout, allowing iteration over the output
        chkdsk.exe /scan /perf 2>&1 | ForEach-Object {
            Write-Debug $_
            # Regex to match the total percentage regardless of windows locale (it's always the second percentage in the status output)
            if ($_ -match "%.*?(\d+)%") {
                [int]$percent = $matches[1]
                if ($percent -gt $oldpercent) {
                    Write-Progress -Id 1 -Activity $childProgressBarActivity -Status "Running chkdsk... ($percent%)" -PercentComplete $percent
                    $oldpercent = $percent
                }
            }
        }
        Write-Progress -Id 1 -Activity $childProgressBarActivity -Status "chkdsk Completed" -PercentComplete 100 -Completed
    }

    function Invoke-SFC {
        <#
        .SYNOPSIS
            Runs sfc on the system drive
        .DESCRIPTION
            SFC /ScanNow - Performs a scan of the system files and fixes any corruption
        .NOTES
            ErrorActionPreference is set locally within a script block & {...} to isolate their effects.
            ErrorActionPreference suppresses false errors caused by sfc.exe output redirection.
            A bug in SFC output buffering causes progress updates to appear in chunks when redirecting output
        #>
        param(
            [int]$parentProgressId = 0
        )
        & {
            $ErrorActionPreference = "SilentlyContinue"
            Write-Progress -Id 1 -ParentId $parentProgressId -Activity $childProgressBarActivity -Status "Running SFC..." -PercentComplete 0
            $oldpercent = 0
            sfc.exe /scannow 2>&1 | ForEach-Object {
                Write-Debug $_
                if ($_ -ne "") {
                    # sfc.exe /scannow outputs unicode characters, so we directly remove null characters for optimization
                    $utf8line = $_ -replace "`0", ""
                    if ($utf8line -match "(\d+)\s*%") {
                        [int]$percent = $matches[1]
                        if ($percent -gt $oldpercent) {
                            Write-Progress -Id 1 -Activity $childProgressBarActivity -Status "Running SFC... ($percent%)" -PercentComplete $percent
                            $oldpercent = $percent
                        }
                    }
                }
            }
            Write-Progress -Id 1 -Activity $childProgressBarActivity -Status "SFC Completed" -PercentComplete 100 -Completed
        }
    }

    function Invoke-DISM {
        <#
        .SYNOPSIS
            Runs DISM on the system drive
        .DESCRIPTION
            DISM                - Fixes system image corruption, and fixes SFC's system image if it was corrupted
              /Online           - Fixes the currently running system image
              /Cleanup-Image    - Performs cleanup operations on the image, could remove some unneeded temporary files
              /Restorehealth    - Performs a scan of the image and fixes any corruption
        #>
        param(
            [int]$parentProgressId = 0
        )
        Write-Progress -Id 1 -ParentId $parentProgressId -Activity $childProgressBarActivity -Status "Running DISM..." -PercentComplete 0
        $oldpercent = 0
        DISM /Online /Cleanup-Image /RestoreHealth | ForEach-Object {
            Write-Debug $_
            # Filter for lines that contain a percentage that is greater than the previous one
            if ($_ -match "(\d+)[.,]\d+%") {
                [int]$percent = $matches[1]
                if ($percent -gt $oldpercent) {
                    # Update the progress bar
                    Write-Progress -Id 1 -Activity $childProgressBarActivity -Status "Running DISM... ($percent%)" -PercentComplete $percent
                    $oldpercent = $percent
                }
            }
        }
        Write-Progress -Id 1 -Activity $childProgressBarActivity -Status "DISM Completed" -PercentComplete 100 -Completed
    }

    try {
        Set-WinUtilTaskbaritem -state "Indeterminate" -overlay "logo"

        $childProgressBarActivity = "Scanning for corruption"
        Write-Progress -Id 0 -Activity "Repairing Windows" -PercentComplete 0
        # Step 1: Run chkdsk to fix disk and filesystem corruption before proceeding with system file repairs
        Invoke-Chkdsk
        Write-Progress -Id 0 -Activity "Repairing Windows" -PercentComplete 25

        # Step 2: Run SFC to fix system file corruption and ensure DISM can operate correctly
        Invoke-SFC
        Write-Progress -Id 0 -Activity "Repairing Windows" -PercentComplete 50

        # Step 3: Run DISM to repair the system image, which SFC relies on for accurate repairs
        Invoke-DISM
        Write-Progress -Id 0 -Activity "Repairing Windows" -PercentComplete 75

        # Step 4: Run SFC again to ensure system files are repaired using the now-fixed system image
        Invoke-SFC
        Write-Progress -Id 0 -Activity "Repairing Windows" -PercentComplete 100 -Completed

        Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"
    } catch {
        Write-Error "An error occurred while repairing the system: $_"
        Set-WinUtilTaskbaritem -state "Error" -overlay "warning"
    } finally {
        Write-Host "==> Finished System Repair"
        Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"
    }

}
```
