function Get-WinUtilServiceStartupType {
    <#
    .SYNOPSIS
        Returns the normalized startup type string for a Windows service.
    #>
    param(
        [Parameter(Mandatory)]
        $Service
    )

    if ($Service.StartType -eq [System.ServiceProcess.ServiceStartMode]::Automatic) {
        $delayed = $null
        try {
            $delayed = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$($Service.Name)" -Name DelayedAutoStart -ErrorAction Stop).DelayedAutoStart
        } catch {
            $delayed = $null
        }

        if ($delayed -eq 1) {
            return 'AutomaticDelayedStart'
        }
    }

    return $Service.StartType.ToString()
}