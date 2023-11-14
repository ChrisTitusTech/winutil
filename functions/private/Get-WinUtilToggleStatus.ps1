Function Get-WinUtilToggleStatus {
    <#

    .SYNOPSIS
        Pulls the registry keys for the given toggle switch and checks whether the toggle should be checked or unchecked

    .PARAMETER ToggleSwitch
        The name of the toggle to check

    .OUTPUTS
        Boolean to set the toggle's status to

    #>

    Param($ToggleSwitch)
    if($ToggleSwitch -eq "WPFToggleDarkMode"){
        $app = (Get-ItemProperty -path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize').AppsUseLightTheme
        $system = (Get-ItemProperty -path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize').SystemUsesLightTheme
        if($app -eq 0 -and $system -eq 0){
            return $true
        }
        else{
            return $false
        }
    }
    if($ToggleSwitch -eq "WPFToggleBingSearch"){
        $bingsearch = (Get-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search').BingSearchEnabled
        if($bingsearch -eq 0){
            return $false
        }
        else{
            return $true
        }
    }
    if($ToggleSwitch -eq "WPFToggleNumLock"){
        $numlockvalue = (Get-ItemProperty -path 'HKCU:\Control Panel\Keyboard').InitialKeyboardIndicators
        if($numlockvalue -eq 2){
            return $true
        }
        else{
            return $false
        }
    }
    if($ToggleSwitch -eq "WPFToggleVerboseLogon"){
        $VerboseStatusvalue = (Get-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System').VerboseStatus
        if($VerboseStatusvalue -eq 1){
            return $true
        }
        else{
            return $false
        }
    }    
    if($ToggleSwitch -eq "WPFToggleShowExt"){
        $hideextvalue = (Get-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced').HideFileExt
        if($hideextvalue -eq 0){
            return $true
        }
        else{
            return $false
        }
    }    
    if($ToggleSwitch -eq "WPFToggleMouseAcceleration"){
        $MouseSpeed = (Get-ItemProperty -path 'HKCU:\Control Panel\Mouse').MouseSpeed
        $MouseThreshold1 = (Get-ItemProperty -path 'HKCU:\Control Panel\Mouse').MouseThreshold1
        $MouseThreshold2 = (Get-ItemProperty -path 'HKCU:\Control Panel\Mouse').MouseThreshold2

        if($MouseSpeed -eq 1 -and $MouseThreshold1 -eq 6 -and $MouseThreshold2 -eq 10){
            return $true
        }
        else{
            return $false
        }
    }
}