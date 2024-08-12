Function Invoke-WinUtilDetailedBSoD {
    <#

    .SYNOPSIS
        Enables/Disables Detailed BSoD
        (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Name 'DisplayParameters').DisplayParameters


    #>
    Param($Enabled)
    try {
        if ($Enabled -eq $false) {
            Write-Host "Enabling Detailed BSoD"
            $value = 1
        } else {
            Write-Host "Disabling Detailed BSoD"
            $value =0
        }

        $Path = "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl"
        $dwords = ("DisplayParameters", "DisableEmoticon")
        foreach ($name in $dwords) {
            Set-ItemProperty -Path $Path -Name $name -Value $value
        }
        Set-ItemProperty -Path $Path -Name DisplayParameters -Value $value
    } catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $Value due to a Security Exception"
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    } catch {
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}
