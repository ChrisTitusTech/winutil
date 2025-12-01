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
        Write-Host "Setting Service $Name to $StartupType"

        # Check if the service exists
        $service = Get-Service -Name $Name -ErrorAction Stop

        # Service exists, proceed with changing properties -- while handling auto delayed start for PWSH 5
        if (($PSVersionTable.PSVersion.Major -lt 7) -and ($StartupType -eq "AutomaticDelayedStart")) {
            # Auto delayed start doesn't work with PWSH 5. That startup type is a combination of both the Automatic startup type,
            # and an additional DWORD value for delayed start. That's how the SCM defines it. For this, we'll go with sc
            #  
            # PWSH 5 uses a built-in enum for service start types: System.ServiceProcess.ServiceStartMode (https://learn.microsoft.com/en-us/dotnet/api/system.serviceprocess.servicestartmode?view=net-10.0-pp)
            # PWSH 7 uses a custom enum for service start types: Microsoft.PowerShell.Commands.ServiceStartupType (https://learn.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.servicestartuptype?view=powershellsdk-7.4.0)
            #
            # ---- That's why this doesn't work on the former!
            
            sc.exe config $Name start=delayed-auto
        } else {
            $service | Set-Service -StartupType $StartupType -ErrorAction Stop
        }
    } catch [System.ServiceProcess.ServiceNotFoundException] {
        Write-Warning "Service $Name was not found"
    } catch {
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $_.Exception.Message
    }

}
