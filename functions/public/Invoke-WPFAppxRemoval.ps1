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

            if ($name -eq "WPFAppxMicrosoft_WindowsNotepad") {
                Stop-Process -Name dllhost
            }

            Write-Host "Removing $name"
            Get-AppxPackage -Name $package -AllUsers | Remove-AppxPackage -AllUsers
        }

        Write-Host "================================="
        Write-Host "--   AppX Removal Finished   ---"
        Write-Host "================================="

        $sync.ProcessRunning = $false
    }
}
