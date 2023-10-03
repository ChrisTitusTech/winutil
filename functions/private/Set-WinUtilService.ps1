Function Set-WinUtilService {
    <#
    
        .DESCRIPTION
        Changes the startup type of services and starts/stops them as needed

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
    
        # Service exists, proceed with changing properties
        $service | Set-Service -StartupType $StartupType -ErrorAction Stop
    }
    catch [System.ServiceProcess.ServiceNotFoundException] {
        Write-Warning "Service $Name was not found"
    }
    catch {
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $_.Exception.Message
    }
    
}
