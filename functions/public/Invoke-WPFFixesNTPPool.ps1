function Invoke-WPFFixesNTPPool {
    <#
    .SYNOPSIS
        Configures Windows to use pool.ntp.org for NTP synchronization

    .DESCRIPTION
        Replaces the default Windows NTP server (time.windows.com) with 
        pool.ntp.org for improved time synchronization accuracy and reliability.
    #>

    Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\w32time\Parameters -Name NtpServer -Value pool.ntp.org,0x9
    Restart-Service w32time

    Write-Host "================================="
    Write-Host "-- NTP Configuration Complete ---"
    Write-Host "================================="
}
