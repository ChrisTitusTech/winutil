function Invoke-WinUtilVerboseLogon {
    <#
    .SYNOPSIS
        Disables/Enables VerboseLogon Messages
    .PARAMETER Enabled
        Indicates whether to enable or disable VerboseLogon messages
    #>
    Param($Enabled)
    Try{
        if ($Enabled -eq $false){
            Write-Host "Enabling Verbose Logon Messages"
            $value = 1
        }
        else {
            Write-Host "Disabling Verbose Logon Messages"
            $value = 0
        }
        $Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Set-ItemProperty -Path $Path -Name VerboseStatus -Value $value
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