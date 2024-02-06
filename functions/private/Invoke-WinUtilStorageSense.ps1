Function Invoke-WinUtilStorageSense {
    <#

    .SYNOPSIS
        Enables/disables Storage Sense.

    .PARAMETER StorageSenseEnabled
        Indicates the current Storage Sense state.

    #>
    Param($StorageSenseEnabled)
    Try{
        if ($StorageSenseEnabled -eq $false){
            Write-Host "Enabling Storage Sense"
            $DesiredStorageSenseState = 1
        } 
        else {
            Write-Host "Disabling Storage Sense"
            $DesiredStorageSenseState = 0
        }

        $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
        Set-ItemProperty -Path $Path -Name "01" -Value $DesiredStorageSenseState
    }
    Catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $Value due to a Security Exception"
    }
    Catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    }
    Catch{
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}