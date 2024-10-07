function Invoke-MicrowinNewFirstRun {

    # using here string to embedd firstrun
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
    Get-ChildItem -Path $taskbarPath -File | Remove-Item -Force
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

    # ************************************************
    # Create WinUtil shortcut on the desktop
    #
    $desktopPath = "$($env:USERPROFILE)\Desktop"
    # Specify the target PowerShell command
    $command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command 'irm https://christitus.com/win | iex'"
    # Specify the path for the shortcut
    $shortcutPath = Join-Path $desktopPath 'winutil.lnk'
    # Create a shell object
    $shell = New-Object -ComObject WScript.Shell

    # Create a shortcut object
    $shortcut = $shell.CreateShortcut($shortcutPath)

    if (Test-Path -Path "$env:HOMEDRIVE\Windows\cttlogo.png") {
        $shortcut.IconLocation = "$env:HOMEDRIVE\Windows\cttlogo.png"
    }

    # Set properties of the shortcut
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$command`""
    # Save the shortcut
    $shortcut.Save()

    # Make the shortcut have 'Run as administrator' property on
    $bytes = [System.IO.File]::ReadAllBytes($shortcutPath)
    # Set byte value at position 0x15 in hex, or 21 in decimal, from the value 0x00 to 0x20 in hex
    $bytes[0x15] = $bytes[0x15] -bor 0x20
    [System.IO.File]::WriteAllBytes($shortcutPath, $bytes)

    Write-Host "Shortcut created at: $shortcutPath"
    #
    # Done create WinUtil shortcut on the desktop
    # ************************************************

    try
    {
        if ((Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -like "Recall" }).Count -gt 0)
        {
            Disable-WindowsOptionalFeature -Online -FeatureName "Recall" -Remove
        }
    }
    catch
    {

    }
'@
    $firstRun | Out-File -FilePath "$env:temp\FirstStartup.ps1" -Force
}
