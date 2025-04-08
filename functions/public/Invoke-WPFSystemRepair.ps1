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

    Write-Progress -Id 0 -Activity "Repairing Windows" -PercentComplete 0
    # Wait for the first progress bar to show, otherwise the second one won't show
    Start-Sleep -Milliseconds 200

    function run_chkdsk {
        <#
        .SYNOPSIS
            Runs chkdsk on the system drive
        .DESCRIPTION
            Chkdsk /Scan - Runs an online scan on the system drive, attempts to fix any corruption, and queues other corruption for fixing on reboot
        .PARAMETER verbose
            If specified, print output from chkdsk
        .NOTES
            VerbosePreference is defined locally, so it only affects this function. This is done by wrapping the code inside a script block and calling it with & { ... }
        #>
        param(
            [switch]$verbose
        )
        & {
            if ($verbose) {
                $VerbosePreference = "Continue"
            }
            else {
                $VerbosePreference = "SilentlyContinue"
            }

            Write-Progress -Id 1 -Activity "Scanning for corruption" -Status "Running chkdsk..." -PercentComplete 0
            $oldpercent = 0
            # 2>&1 redirects stdout, allowing iteration over the output
            chkdsk.exe /scan /perf 2>&1 | ForEach-Object {
                Write-Verbose $_
                # Regex to match the total percentage regardless of windows locale (it's always the second percentage in the status output)
                if ($_ -match "%.*?(\d+)%") {
                    [int]$percent = $matches[1]
                    if ($percent -gt $oldpercent) {
                        Write-Progress -Id 1 -ParentId 0 -Activity "Scanning for corruption" -Status "Running chkdsk... ($percent%)" -PercentComplete $percent    
                        $oldpercent = $percent
                    }   
                }
            }
            Write-Progress -Id 1 -Activity "Scanning for corruption" -Status "chkdsk Completed" -PercentComplete 100    
        }
    }
    
    function run_sfc {
        <#
        .SYNOPSIS
            Runs sfc on the system drive
        .DESCRIPTION
            SFC /ScanNow - Performs a scan of the system files and fixes any corruption
        .PARAMETER verbose
            If specified, print output from sfc
        .NOTES
            VerbosePreference and ErrorPreference is defined locally, so it only affects this function. This is done by wrapping the code inside a script block and calling it with & { ... }
        #>
        param(
            [switch]$verbose
        )

        & {
            if ($verbose) {
                $VerbosePreference = "Continue"
            }
            else {
                $VerbosePreference = "SilentlyContinue"
            }
            $ErrorActionPreference = "SilentlyContinue"
            Write-Progress -Id 1 -ParentId 0 -Activity "Scanning for corruption" -Status "Running SFC..." -PercentComplete 0
            $oldpercent = 0
            # SFC has a bug when redirected which causes it to output only when the stdout buffer is full, causing the progress bar to move in chunks
            sfc.exe /scannow 2>&1 | ForEach-Object {
                Write-Verbose $_
                if ($_ -ne "") {
                    # sfc.exe /scannow outputs unicode characters, so we directly remove null characters for optimization
                    $utf8line = $_ -replace "`0", ""
                    if ($utf8line -match "(\d+)\s%") {
                        # Write-Host "$($matches[0]) $($matches[1])"
                        [int]$percent = $matches[1]
                        if ($percent -gt $oldpercent) {
                            Write-Progress -Id 1 -ParentId 0 -Activity "Scanning for corruption" -Status "Running SFC... ($percent%)" -PercentComplete $percent    
                            $oldpercent = $percent
                        }    
                    }
                }
            }
            Write-Progress -Id 1 -ParentId 0 -Activity "Scanning for corruption" -Status "SFC Completed" -PercentComplete 100
        } 
    }
    
    function run_dism {
        <#
        .SYNOPSIS
            Runs DISM on the system drive
        .DESCRIPTION
            DISM                - Fixes system image corruption, and fixes SFC's system image if it was corrupted
              /Online           - Fixes the currently running system image
              /Cleanup-Image    - Performs cleanup operations on the image, could remove some unneeded temporary files
              /Restorehealth    - Performs a scan of the image and fixes any corruption

        .PARAMETER verbose  
            If specified, print output from DISM
        .NOTES
            VerbosePreference is defined locally, so it only affects this function. This is done by wrapping the code inside a script block and calling it with & { ... }
        #>
        param(
            [switch]$verbose
        )
        & {
            if ($verbose) {
                $VerbosePreference = "Continue"
            }
            else {
                $VerbosePreference = "SilentlyContinue"
            }
        
            Write-Progress -Id 1 -ParentId 0 -Activity "Scanning for corruption" -Status "Running DISM..." -PercentComplete 0
            $oldpercent = 0
            DISM /Online /Cleanup-Image /RestoreHealth | ForEach-Object {
                Write-Verbose $_
        
                # Filter for lines that contain a percentage that is greater than the previous one
                if ($_ -match "(\d+)[.,]\d+%") {
                    [int]$percent = $matches[1]
                    if ($percent -gt $oldpercent) {
                        # Update the progress bar
                        Write-Progress -Id 1 -ParentId 0 -Activity "Scanning for corruption" -Status "Running DISM... ($percent%)" -PercentComplete $percent
                        $oldpercent = $percent
                    }
                }
            }
            Write-Progress -Id 1 -ParentId 0 -Activity "Scanning for corruption" -Status "DISM Completed" -PercentComplete 100   
        }    
    }

    # Scan system for corruption
    Write-Progress -Id 0 -Activity "Repairing Windows" -Status "Scanning for corruption... " -PercentComplete 0
    # Step 1: Run chkdsk to fix disk and filesystem corruption before proceeding with system file repairs
    run_chkdsk
    Write-Progress -Id 0 -Activity "Repairing Windows" -Status "Scanning for corruption... (25%)" -PercentComplete 25

    # Step 2: Run SFC to fix system file corruption and ensure DISM can operate correctly
    run_sfc
    Write-Progress -Id 0 -Activity "Repairing Windows" -Status "Scanning for corruption... (50%)" -PercentComplete 50

    # Step 3: Run DISM to repair the system image, which SFC relies on for accurate repairs
    run_dism
    Write-Progress -Id 0 -Activity "Repairing Windows" -Status "Scanning for corruption... (75%)" -PercentComplete 75

    # Step 4: Run SFC again to ensure system files are repaired using the now-fixed system image
    run_sfc
    Write-Progress -Id 0 -Activity "Repairing Windows" -Status "Scanning for corruption completed" -PercentComplete 100
}