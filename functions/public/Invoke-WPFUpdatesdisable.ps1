function Invoke-WPFUpdatesdisable {
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

    Write-WinUtilLog -Component "Updates" -Message "================================="
    Write-WinUtilLog -Component "Updates" -Message "---   Updates Are Disabled    ---"
    Write-WinUtilLog -Component "Updates" -Message "================================="

    Write-WinUtilLog -Component "Updates" -Message "Windows Update disable workflow completed. Restart required."
}
