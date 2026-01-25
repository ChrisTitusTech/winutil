function Microwin-NewFirstRun {

    # using here string to embed firstrun
    $firstRun = @'
    # Set the global error action preference to continue
    $ErrorActionPreference = "Continue"

    "FirstStartup has worked" | Out-File -FilePath "$env:HOMEDRIVE\windows\LogFirstRun.txt" -Append -NoClobber

    Remove-Item "$Env:AppData\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*"
    
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Name "FavoritesRemovedChanges"
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Name "FavoritesChanges"
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Name "Favorites"

    # Remove Edge Icon From the Desktop
    Remove-Item "$Env:Public\Desktop\Microsoft Edge.lnk"

    if ((Get-WindowsOptionalFeature -Online | Where-Object FeatureName -eq 'Recall').State -eq 'Enabled') {
        Disable-WindowsOptionalFeature -Online -FeatureName "Recall" -Remove
    }

    # Get BCD entries and set bootmgr timeout accordingly
    
    # Check if the number of occurrences of "path" is 2 - this fixes the Boot Manager screen issue (#2562)
    if ((bcdedit | Select-String "path").Count -eq 2) {
        # Set bootmgr timeout to 0
        bcdedit /set `{bootmgr`} timeout 0
    }

    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested" /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.Suggested" /v Enabled /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.StartupApp" /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.StartupApp" /v Enabled /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Microsoft.SkyDrive.Desktop" /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Microsoft.SkyDrive.Desktop" /v Enabled /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.AccountHealth" /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.AccountHealth" /v Enabled /t REG_DWORD /d 0 /f

    # This will set List view in Start menu on Win11 25H2. This will not do anything in 24H2 and older
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Start" /v AllAppsViewMode /t REG_DWORD /d 2 /f

    # Other Start Menu settings
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_AccountNotifications /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Start" /v ShowAllPinsList /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Start" /v ShowFrequentList /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Start" /v ShowRecentList /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackDocs /t REG_DWORD /d 0 /f

    # Set Windows to Dark Mode
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f

    Stop-Process -Name explorer

    if (Test-Path -Path "$env:HOMEDRIVE\winutil-config.json")
    {
        Write-Host "Configuration file detected. Applying..."
        iex "& { $(irm christitus.com/win) } -Config `"$env:HOMEDRIVE\winutil-config.json`" -Run"
    }

'@
    $firstRun | Out-File -FilePath "$env:temp\FirstStartup.ps1" -Force
}
