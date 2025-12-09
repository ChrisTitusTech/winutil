function Invoke-WPFUpdatessecurity {
    <#

    .SYNOPSIS
        Sets Windows Update to recommended settings

    .DESCRIPTION
        Disables driver offering through Windows Update

    #>
        Write-Host "Excluding drivers from windows updates"

        $Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        
        New-Item $Path -Force | Out-Null
        Set-ItemProperty $Path -Name ExcludeWUDriversInQualityUpdate -Value 1 -Type DWord

        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = "Set Security Updates"
        $Messageboxbody = ("Recommended Update settings loaded")
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)
        Write-Host "================================="
        Write-Host "-- Updates Set to Recommended ---"
        Write-Host "================================="
}
