function Invoke-WPFAppxRemoval {
    $selected = $sync.selectedAppx
    $apps = $sync.configs.appxHashtable

    Get-Process -Name *widget*, *game*, dllhost -ErrorAction SilentlyContinue | Stop-Process -Force
    $handle = Invoke-WPFRunspace -ParameterList @(("selected", $selected), ("apps", $apps)) -ScriptBlock {
        param($selected, $apps)

        $sync.ProcessRunning = $true

        foreach ($key in $selected) {
            $package = $apps[$key].PackageId

            Write-Host "Removing $package"
            Get-AppxPackage -Name $package -AllUsers | Remove-AppxPackage -AllUsers
        }

        Write-Host "================================="
        Write-Host "--   AppX Removal Finished   ---"
        Write-Host "================================="

        $sync.ProcessRunning = $false
    }
}
