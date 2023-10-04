function Invoke-WPFPanelAutologin {
    <#

    .SYNOPSIS
        Enables autologin using Sysinternals Autologon.exe

    #>
    curl.exe -ss "https://live.sysinternals.com/Autologon.exe" -o $env:temp\autologin.exe # Official Microsoft recommendation https://learn.microsoft.com/en-us/sysinternals/downloads/autologon
    cmd /c $env:temp\autologin.exe /accepteula
}