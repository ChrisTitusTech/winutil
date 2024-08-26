function Invoke-WPFPanelDISM {
    <#

    .SYNOPSIS
        Checks for system corruption using Chkdsk, SFC, and DISM

    .DESCRIPTION
        1. Chkdsk    - Fixes disk and filesystem corruption
        2. SFC Run 1 - Fixes system file corruption, and fixes DISM if it was corrupted
        3. DISM      - Fixes system image corruption, and fixes SFC's system image if it was corrupted
        4. SFC Run 2 - Fixes system file corruption, this time with an almost guaranteed uncorrupted system image

    .NOTES
        Command Arguments:
            1. Chkdsk
                /Scan - Runs an online scan on the system drive, attempts to fix any corruption, and queues other corruption for fixing on reboot
            2. SFC
                /ScanNow - Performs a scan of the system files and fixes any corruption
            3. DISM      - Fixes system image corruption, and fixes SFC's system image if it was corrupted
                /Online - Fixes the currently running system image
                /Cleanup-Image - Performs cleanup operations on the image, could remove some unneeded temporary files
                /Restorehealth - Performs a scan of the image and fixes any corruption

    #>
    Start-Process PowerShell -ArgumentList "Write-Host '(1/4) Chkdsk' -ForegroundColor Green; Chkdsk /scan;
    Write-Host '`n(2/4) SFC - 1st scan' -ForegroundColor Green; sfc /scannow;
    Write-Host '`n(3/4) DISM' -ForegroundColor Green; DISM /Online /Cleanup-Image /Restorehealth;
    Write-Host '`n(4/4) SFC - 2nd scan' -ForegroundColor Green; sfc /scannow;
    Read-Host '`nPress Enter to Continue'" -verb runas
}
