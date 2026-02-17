function Invoke-WPFSystemRepair {
    <#
    .SYNOPSIS
        Checks for system corruption using SFC, and DISM

    .DESCRIPTION
        1. SFC - Fixes system file corruption, and fixes DISM if it was corrupted
        2. DISM - Fixes system image corruption, and fixes SFC's system image if it was corrupted
        3. Chkdsk - Checks for disk errors, which can cause system file corruption and notifies of early disk failure
    #>
    Start-Process cmd.exe -ArgumentList "/c chkdsk.exe /scan /perf" -NoNewWindow -Wait
    Start-Process cmd.exe -ArgumentList "/c sfc /scannow" -NoNewWindow -Wait
    Start-Process cmd.exe -ArgumentList "/c dism /online /cleanup-image /restorehealth" -NoNewWindow -Wait

    Write-Host "==> Finished System Repair"
    Set-WinUtilTaskbaritem -state "None" -overlay "checkmark"
}
