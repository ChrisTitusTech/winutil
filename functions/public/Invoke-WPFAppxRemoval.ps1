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
            $package = $apps[$key].PackageId
            $name = $apps[$key].Content

            if ($key -eq "WPFAppxMicrosoft_WindowsNotepad") {
                # Notepad uses dllhost, this will close Windows Settings if open
                Stop-Process -Name dllhost
            }

            Write-Host "Removing $name"
            Get-AppxPackage -Name $package -AllUsers | Remove-AppxPackage -AllUsers

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
