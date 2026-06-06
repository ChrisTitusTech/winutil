Function Set-WinUtilService {
    <#

    .SYNOPSIS
        Changes the startup type of the given service

    .PARAMETER Name
        The name of the service to modify

    .PARAMETER StartupType
        The startup type to set the service to

    .EXAMPLE
        Set-WinUtilService -Name "HomeGroupListener" -StartupType "Manual"

    #>
    param (
        $Name,
        $StartupType
    )
    try {
        $service = Get-Service -Name $Name -ErrorAction Stop
        $currentStartupType = Get-WinUtilServiceStartupType -Service $service

        if ($currentStartupType -eq $StartupType) {
            Write-Host "Skip Service $Name - already set to $StartupType"
            return
        }

        Write-Host "Setting Service $Name to $StartupType"

        if (($PSVersionTable.PSVersion.Major -lt 7) -and ($StartupType -eq "AutomaticDelayedStart")) {
            sc.exe config "$Name" start=delayed-auto
        } else {
            $service | Set-Service -StartupType $StartupType -ErrorAction Stop
        }
    } catch {
        if (Test-WinUtilIsServiceNotFoundException -Exception $_.Exception) {
            Write-Warning "Service $Name was not found."
            return
        }
        Write-Warning "Unable to set $Name due to unhandled exception."
        Write-Warning $_.Exception.Message
    }

}