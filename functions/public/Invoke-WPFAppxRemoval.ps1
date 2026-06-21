function Invoke-WPFAppxRemoval {
    if ($sync.ProcessRunning) {
        [System.Windows.MessageBox]::Show("A process is currently running.", "Winutil", "OK", "Warning")
        return
    }

    $selected = @($sync.selectedAppx)
    if (-not $selected) {
        [System.Windows.MessageBox]::Show("Select AppX packages to remove.", "Winutil", "OK", "Warning")
        return
    }

    $apps = $sync.configs.appxHashtable

    Invoke-WPFRunspace -ParameterList @(("selected", $selected),("apps", $apps)) -ScriptBlock {
        param($selected, $apps)

        $sync.ProcessRunning = $true

        foreach ($key in $selected) {
            $package = $apps[$key].PackageId

            Write-Host "Removing $package"
            Get-AppxPackage -Name $package -AllUsers | Remove-AppxPackage -AllUsers
        }

        $sync.ProcessRunning = $false

        Write-Host "================================="
        Write-Host "--   AppX Removal Finished   ---"
        Write-Host "================================="
    }
}
