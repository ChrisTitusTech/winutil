Function Get-WinUtilDarkMode {
    <#
    
        .DESCRIPTION
        Meant to pull the registry keys responsible for Dark Mode and returns true or false
    
    #>
    $app = (Get-ItemProperty -path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize').AppsUseLightTheme
    $system = (Get-ItemProperty -path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize').SystemUsesLightTheme
    if($app -eq 0 -and $system -eq 0){
        return $true
    } 
    else{
        return $false
    }
}