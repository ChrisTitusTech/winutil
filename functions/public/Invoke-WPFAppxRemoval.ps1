function Invoke-WPFAppxRemoval {
    if (-not ($sync.selectedAppx)) {
        [System.Windows.Forms.MessageBox]::Show("No AppX Package selected","Error","OK","Error")
        return
    }

    $selected = $sync.selectedAppx
    $apps = $sync.configs.appxHashtable

    $handle = Invoke-WPFRunspace -ParameterList @(("selected", $selected), ("apps", $apps)) -ScriptBlock {
        param($selected, $apps)

        $sync.ProcessRunning = $true

        foreach ($key in $selected) {
            if ($key -eq "WPFAppxMicrosoft_XboxGamingOverlay") {
                # Making sure Game Bar isn't running
                Stop-Process -Name GameBarFTServer

                # This stops annoying ms-gamebar popup when launching games.
                Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR -Name AppCaptureEnabled -Value 0
            }

            Write-Host "Removing $($apps[$key].Content)"
            Get-AppxPackage -Name $apps[$key].PackageId -AllUsers | Remove-AppxPackage -AllUsers
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $apps[$key].PackageId | Remove-AppxProvisionedPackage -Online

            if ($key -eq "WPFAppxMSTeams") {
                # Uninstalls Microsoft Teams Meeting Add-in for Microsoft Office
                Get-Package -Name "Microsoft Teams*" -ErrorAction SilentlyContinue | Uninstall-Package -Force
            }
        }

        Write-Host "================================="
        Write-Host "--   AppX Removal Finished   ---"
        Write-Host "================================="

        $sync.ProcessRunning = $false
    }
}
