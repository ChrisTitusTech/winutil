function Invoke-WPFUpdatesdisable {
    Write-WinUtilLog -Component "Updates" -Message "Configuring Windows Update registry policy values for disable mode."
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force

    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Type DWord -Value 1

    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Force
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 0

    Write-WinUtilLog -Component "Updates" -Message "Disabling wuauserv service."
    Set-Service -Name wuauserv -StartupType Disabled

    Write-WinUtilLog -Component "Updates" -Message "Disabling UsoSvc service."
    Set-Service -Name UsoSvc -StartupType Disabled

    Write-WinUtilLog -Component "Updates" -Message "Disabling update related dll files."

    takeown /f $Env:SystemRoot\System32\usosvc.dll
    icacls $Env:SystemRoot\System32\usosvc.dll /grant Everyone:F
    Rename-Item -Path $Env:SystemRoot\System32\usosvc.dll -NewName usosvc.dlle

    Write-WinUtilLog -Component "Updates" -Message "Clearing SoftwareDistribution folder."
    Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue

    Write-WinUtilLog -Component "Updates" -Message "Windows Update disable workflow completed. Restart required."
}
