function Microwin-NewFirstRun {

    # using here string to embed firstrun
    $firstRun = @'
    # Set the global error action preference to continue
    $ErrorActionPreference = "Continue"
    function Remove-RegistryValue {
        param (
            [Parameter(Mandatory = $true)]
            [string]$RegistryPath,

            [Parameter(Mandatory = $true)]
            [string]$ValueName
        )

        # Check if the registry path exists
        if (Test-Path -Path $RegistryPath) {
            $registryValue = Get-ItemProperty -Path $RegistryPath -Name $ValueName -ErrorAction SilentlyContinue

            # Check if the registry value exists
            if ($registryValue) {
                # Remove the registry value
                Remove-ItemProperty -Path $RegistryPath -Name $ValueName -Force
                Write-Host "Registry value '$ValueName' removed from '$RegistryPath'."
            } else {
                Write-Host "Registry value '$ValueName' not found in '$RegistryPath'."
            }
        } else {
            Write-Host "Registry path '$RegistryPath' not found."
        }
    }

    "FirstStartup has worked" | Out-File -FilePath "$env:HOMEDRIVE\windows\LogFirstRun.txt" -Append -NoClobber

    $taskbarPath = "$env:AppData\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
    # Delete all files on the Taskbar
    if (Test-Path "$taskbarPath") {
        Get-ChildItem -Path $taskbarPath -File | Remove-Item -Force
    }
    Remove-RegistryValue -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -ValueName "FavoritesRemovedChanges"
    Remove-RegistryValue -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -ValueName "FavoritesChanges"
    Remove-RegistryValue -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -ValueName "Favorites"

    # Delete Edge Icon from the desktop
    $edgeShortcutFiles = Get-ChildItem -Path $desktopPath -Filter "*Edge*.lnk"
    # Check if Edge shortcuts exist on the desktop
    if ($edgeShortcutFiles) {
        foreach ($shortcutFile in $edgeShortcutFiles) {
            # Remove each Edge shortcut
            Remove-Item -Path $shortcutFile.FullName -Force
            Write-Host "Edge shortcut '$($shortcutFile.Name)' removed from the desktop."
        }
    }
    Remove-Item -Path "$env:USERPROFILE\Desktop\*.lnk"
    Remove-Item -Path "$env:HOMEDRIVE\Users\Default\Desktop\*.lnk"

    try
    {
        if ((Get-WindowsOptionalFeature -Online | Where-Object { $_.State -eq 'Enabled' -and $_.FeatureName -like "Recall" }).Count -gt 0)
        {
            Disable-WindowsOptionalFeature -Online -FeatureName "Recall" -Remove
        }
    }
    catch
    {

    }

    # Get BCD entries and set bootmgr timeout accordingly
    try
    {
        # Check if the number of occurrences of "path" is 2 - this fixes the Boot Manager screen issue (#2562)
        if ((bcdedit | Select-String "path").Count -eq 2)
        {
            # Set bootmgr timeout to 0
            bcdedit /set `{bootmgr`} timeout 0
        }
    }
    catch
    {

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

    # This will disable the Recommendations in 25H2. This is much simpler than the method used in 24H2 that requires the Education Environment policy
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_IrisRecommendations /t REG_DWORD /d 0 /f

    # Other Start Menu settings
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_AccountNotifications /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Start" /v ShowAllPinsList /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Start" /v ShowFrequentList /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Start" /v ShowRecentList /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackDocs /t REG_DWORD /d 0 /f

    # Color Modes -- requires sending messages to apply to everything
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f

    # Send the WM_SETTINGCHANGE message to all windows
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd,
        uint Msg,
        IntPtr wParam,
        string lParam,
        uint fuFlags,
        uint uTimeout,
        out IntPtr lpdwResult);
}
"@

    $HWND_BROADCAST = [IntPtr]0xffff
    $WM_SETTINGCHANGE = 0x1A
    $SMTO_ABORTIFHUNG = 0x2
    $timeout = 100

    # Send the broadcast message to all windows
    [Win32]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [IntPtr]::Zero, "ImmersiveColorSet", $SMTO_ABORTIFHUNG, $timeout, [ref]([IntPtr]::Zero))

    Clear-Host
    Write-Host "The taskbar will take around a minute to show up, but you can start using your computer now. Try pressing the Windows key to open the Start menu, or Windows + E to launch File Explorer."
    Start-Sleep -Seconds 10

    if (Test-Path -Path "$env:HOMEDRIVE\winutil-config.json")
    {
        Write-Host "Configuration file detected. Applying..."
        iex "& { $(irm christitus.com/win) } -Config `"$env:HOMEDRIVE\winutil-config.json`" -Run"
    }

'@
    $firstRun | Out-File -FilePath "$env:temp\FirstStartup.ps1" -Force
}
