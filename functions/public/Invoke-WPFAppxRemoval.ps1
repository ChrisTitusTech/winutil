function Invoke-WPFAppxRemoval {
    if ($null -eq $sync.selectedAppx -or $sync.selectedAppx.Count -eq 0) {
        Show-WinUtilMessage -Message "No AppX Package selected" -Title "Error" -Button "OK" -Icon "Error"
        return
    }

    $selected = $sync.selectedAppx
    $apps = $sync.configs.appxHashtable

    Invoke-WPFRunspace -ParameterList @(("selected", $selected), ("apps", $apps)) -ScriptBlock {
        param($selected, $apps)

        $sync.ProcessRunning = $true
        Write-WinUtilLog -Component "AppX" -Message "Starting AppX removal for $(@($selected).Count) selected package(s)."

        $packageList = [System.Collections.Generic.List[string]]::new()

        foreach ($key in $selected) {
            if ($key -eq "WPFAppxMicrosoft_XboxGamingOverlay") {
                # Making sure Game Bar isn't running
                Write-WinUtilLog -Component "AppX" -Message "Stopping GameBarFTServer before removing Xbox Gaming Overlay."
                Stop-Process -Name GameBarFTServer -Force -Confirm:$false -ErrorAction SilentlyContinue

                # This stops annoying ms-gamebar popup when launching games.
                Write-WinUtilLog -Component "AppX" -Message "Disabling Game DVR capture before removing Xbox Gaming Overlay."
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR -Name AppCaptureEnabled -Value 0
            }

            if ($key -eq "WPFAppxMicrosoft_WindowsNotepad") {
                Write-WinUtilLog -Component "AppX" -Message "Stopping dllhost before removing Notepad."
                Stop-Process -Name dllhost -Force -Confirm:$false -ErrorAction SilentlyContinue
            }

            Write-Host "Removing $($apps[$key].Content)"
            Write-WinUtilLog -Component "AppX" -Message "Removing $($apps[$key].Content) ($($apps[$key].PackageId))."
            Remove-WinUtilAPPX -Name $apps[$key].PackageId
            $packageList.Add($apps[$key].PackageId)

            if ($key -eq "WPFAppxMSTeams") {
                # Uninstalls Microsoft Teams Meeting Add-in for Microsoft Office
                Write-WinUtilLog -Component "AppX" -Message "Uninstalling Microsoft Teams meeting add-in package."
                Get-Package -Name "Microsoft Teams*" -ErrorAction SilentlyContinue | Uninstall-Package -Force
            }
        }

        if ($packageList.Count -gt 0) {
            Remove-WinUtilProvisionedAPPX -PackageList $packageList.ToArray()
        }

        Write-Host "================================="
        Write-Host "--   AppX Removal Finished   ---"
        Write-Host "================================="
        Write-WinUtilLog -Component "AppX" -Message "AppX removal finished."

        $sync.ProcessRunning = $false
    }
}
