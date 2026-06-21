function Invoke-WPFAppxRemoval {
    <#
    .SYNOPSIS
        Removes the selected AppX packages in a background runspace.
    #>

    if ($sync.ProcessRunning) {
        $msg = "A process is currently running. Please wait for it to finish."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $selected = @($sync.selectedAppx)
    if ($selected.Count -eq 0) {
        $msg = "Please select the AppX packages you wish to remove."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $totalSteps = $selected.Count
    $completedSteps = 0

    $handle = Invoke-WPFRunspace -ParameterList @(("selected", $selected), ("completedSteps", $completedSteps), ("totalSteps", $totalSteps)) -ScriptBlock {
        param($selected, $completedSteps, $totalSteps)

        $sync.ProcessRunning = $true

        for ($i = 0; $i -lt $selected.Count; $i++) {
            $key = $selected[$i]
            $appInfo = $sync.configs.appxHashtable.$key
            $packageId = $appInfo.PackageId

            Write-Host "Removing $packageId"
            Get-AppxPackage -Name $packageId -AllUsers | Remove-AppxPackage -AllUsers
        }

        $sync.ProcessRunning = $false

        Write-Host "================================="
        Write-Host "--   AppX Removal Finished   ---"
        Write-Host "================================="
    }
}
