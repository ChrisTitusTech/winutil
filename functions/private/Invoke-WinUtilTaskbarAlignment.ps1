function Invoke-WinUtilTaskbarAlignment {
    <#

    .SYNOPSIS
        Switches between Center & Left Taskbar Alignment

    .PARAMETER Enabled
        Indicates whether to make Taskbar Alignment Center or Left

    #>
    Param($Enabled)
    Try{
        if ($Enabled -eq $false){
            Write-Host "Making Taskbar Alignment to the Center"
            $value = 1
        }
        else {
            Write-Host "Making Taskbar Alignment to the Left"
            $value = 0
        }
        $Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $Path -Name "TaskbarAl" -Value $value
    }
    Catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $value due to a Security Exception"
    }
    Catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    }
    Catch{
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}
