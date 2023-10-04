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
}