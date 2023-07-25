Function Get-WinUtilToggleStatus {
    <#
    
        .DESCRIPTION
        Meant to pull the registry keys for a toggle switch and returns true or false

        True should mean status is enabled
        False should mean status is disabled
    
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
}