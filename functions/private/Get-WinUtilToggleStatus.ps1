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
    if($ToggleSwitch -eq "WPFToggleSnapWindow"){
        $hidesnap = (Get-ItemProperty -path 'HKCU:\Control Panel\Desktop').WindowArrangementActive
        if($hidesnap -eq 0){
            return $false
        }
        else{
            return $true
        }
    }
    if($ToggleSwitch -eq "WPFToggleSnapFlyout"){
        $hidesnap = (Get-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced').EnableSnapAssistFlyout
        if($hidesnap -eq 0){
            return $false
        }
        else{
            return $true
        }
    }
    if($ToggleSwitch -eq "WPFToggleSnapSuggestion"){
        $hidesnap = (Get-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced').SnapAssist
        if($hidesnap -eq 0){
            return $false
        }
        else{
            return $true
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
    if($ToggleSwitch -eq "WPFToggleTaskbarSearch"){
        $SearchButton = (Get-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search").SearchboxTaskbarMode
        if($SearchButton -eq 0){
            return $false
        }
        else{
            return $true
        }
    }
    if ($ToggleSwitch -eq "WPFToggleStickyKeys") {
        $StickyKeys = (Get-ItemProperty -path 'HKCU:\Control Panel\Accessibility\StickyKeys').Flags
        if($StickyKeys -eq 58){
            return $false
        }
        else{
            return $true
        }
    }
    if ($ToggleSwitch -eq "WPFToggleTaskView") {
        $TaskView = (Get-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced').ShowTaskViewButton
        if($TaskView -eq 0){
            return $false
        }
        else{
            return $true
        }
    }

    if ($ToggleSwitch -eq "WPFToggleHiddenFiles") {
        $HiddenFiles = (Get-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced').Hidden
        if($HiddenFiles -eq 0){
            return $false
        }
        else{
            return $true
        }
    }

    if ($ToggleSwitch -eq "WPFToggleTaskbarWidgets") {
        $TaskbarWidgets = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced").TaskBarDa
        if($TaskbarWidgets -eq 0) {
            return $false
        }
        else{
            return $true
        }
    }
    if ($ToggleSwitch -eq "WPFToggleTaskbarAlignment") {
        $TaskbarAlignment = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced").TaskbarAl
        if($TaskbarAlignment -eq 0) {
            return $false
        }
        else{
            return $true
        }
    }
    if ($ToggleSwitch -eq "WPFToggleDetailedBSoD") {
        $DetailedBSoD = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl').DisplayParameters
        if($DetailedBSoD -eq 0) {
            return $false
        }
        else{
            return $true
        }
    }
}
