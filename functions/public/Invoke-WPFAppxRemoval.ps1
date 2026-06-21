function Invoke-WPFAppxRemoval {
    $apps = $sync.configs.appxHashtable

    Invoke-WPFRunspace -ParameterList @(("selected", $selected),("apps", $apps)) -ScriptBlock {
        param($selected, $apps)

        foreach ($key in $selected) {
            $package = $apps[$key].PackageId
            Write-Host "Removing $package"
            Get-AppxPackage -Name $package -AllUsers | Remove-AppxPackage -AllUsers
        }

        Write-Host "================================="
        Write-Host "--   AppX Removal Finished   ---"
        Write-Host "================================="
    }
}
