Function Invoke-WinUtilDetailedBSoD {
    <#

    .SYNOPSIS
        Enables/Disables Detailed BSoD
        (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Name 'DisplayParameters').DisplayParameters
        

    #>
    Param($Enabled)
    Try{
        if ($Enabled -eq $false){
            Write-Host "Enabling Detailed BSoD"
            $value = 1
        }
        else {
            Write-Host "Disabling Detailed BSoD"
            $value =0
        }

        $Path = "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl"
        Set-ItemProperty -Path $Path -Name DisplayParameters -Value $value
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