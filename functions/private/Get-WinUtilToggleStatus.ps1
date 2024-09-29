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
    if($ToggleSwitch -eq "WPFToggleDarkMode") {
        $app = (Get-ItemProperty -path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize').AppsUseLightTheme
        $system = (Get-ItemProperty -path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize').SystemUsesLightTheme
        return $app -eq 0 -and $system -eq 0
    }
    if($ToggleSwitch -eq "WPFToggleBingSearch") {
        $bingsearch = (Get-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search').BingSearchEnabled
        return $bingsearch -ne 0
    }
    if($ToggleSwitch -eq "WPFToggleNumLock") {
        $numlockvalue = (Get-ItemProperty -path 'HKCU:\Control Panel\Keyboard').InitialKeyboardIndicators
        return $numlockvalue -eq 2
    }
    if($ToggleSwitch -eq "WPFToggleVerboseLogon") {
        $VerboseStatusvalue = (Get-ItemProperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System').VerboseStatus
        return $VerboseStatusvalue -eq 1
    }
    if($ToggleSwitch -eq "WPFToggleShowExt") {
        $hideextvalue = (Get-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced').HideFileExt
        return $hideextvalue -eq 0
    }
    if($ToggleSwitch -eq "WPFToggleSnapWindow") {
        $hidesnap = (Get-ItemProperty -path 'HKCU:\Control Panel\Desktop').WindowArrangementActive
        return $hidesnap -ne 0
    }
    if($ToggleSwitch -eq "WPFToggleSnapFlyout") {
        $hidesnap = (Get-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced').EnableSnapAssistFlyout
        return $hidesnap -ne 0
    }
    if($ToggleSwitch -eq "WPFToggleSnapSuggestion") {
        $hidesnap = (Get-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced').SnapAssist
        return $hidesnap -ne 0
    }
    if($ToggleSwitch -eq "WPFToggleMouseAcceleration") {
        $MouseSpeed = (Get-ItemProperty -path 'HKCU:\Control Panel\Mouse').MouseSpeed
        $MouseThreshold1 = (Get-ItemProperty -path 'HKCU:\Control Panel\Mouse').MouseThreshold1
        $MouseThreshold2 = (Get-ItemProperty -path 'HKCU:\Control Panel\Mouse').MouseThreshold2

        return $MouseSpeed -eq 1 -and $MouseThreshold1 -eq 6 -and $MouseThreshold2 -eq 10
    }
    if($ToggleSwitch -eq "WPFToggleTaskbarSearch") {
        $SearchButton = (Get-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search").SearchboxTaskbarMode
        return $SearchButton -ne 0
    }
    if ($ToggleSwitch -eq "WPFToggleStickyKeys") {
        $StickyKeys = (Get-ItemProperty -path 'HKCU:\Control Panel\Accessibility\StickyKeys').Flags
        return $StickyKeys -ne 58
    }
    if ($ToggleSwitch -eq "WPFToggleTaskView") {
        $TaskView = (Get-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced').ShowTaskViewButton
        return $TaskView -ne 0
    }

    if ($ToggleSwitch -eq "WPFToggleHiddenFiles") {
        $HiddenFiles = (Get-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced').Hidden
        return $HiddenFiles -ne 0
    }

    if ($ToggleSwitch -eq "WPFToggleTaskbarWidgets") {
        $TaskbarWidgets = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced").TaskBarDa
        return $TaskbarWidgets -ne 0
    }
    if ($ToggleSwitch -eq "WPFToggleTaskbarAlignment") {
        $TaskbarAlignment = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced").TaskbarAl
        return $TaskbarAlignment -ne 0
    }
    if ($ToggleSwitch -eq "WPFToggleDetailedBSoD") {
        $DetailedBSoD1 = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl').DisplayParameters
        $DetailedBSoD2 = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl').DisableEmoticon
        return !(($DetailedBSoD1 -eq 0) -or ($DetailedBSoD2 -eq 0) -or !$DetailedBSoD1 -or !$DetailedBSoD2)
    }
}
