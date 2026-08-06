function Invoke-WPFAppxInstall {
    if ($null -eq $sync.selectedAppx -or $sync.selectedAppx.Count -eq 0) {
        Show-WinUtilMessage -Message "No AppX Package selected" -Title "Error" -Button "OK" -Icon "Error"
        return
    }

    Start-WinUtilJob -Name "AppX install" -Description "Installing AppX packages" -Parameters @{
        Selected = @($sync.selectedAppx)
        Apps = $sync.configs.appxHashtable
    } -ScriptBlock {
        param($Selected, $Apps)

        $totalPackages = @($Selected).Count
        Write-WinUtilLog -Component "AppX" -Message "Starting AppX install for $totalPackages selected package(s)."

        for ($index = 0; $index -lt $totalPackages; $index++) {
            $app = $Apps[$Selected[$index]]
            $position = $index + 1

            Write-WinUtilJobProgress -Status "Installing $($app.Content) ($position/$totalPackages)" -Percent ([int](($index / $totalPackages) * 100))
            Write-Host "Installing $($app.Content)"
            Install-WinUtilAPPX -Name $app.PackageId -StoreId $app.StoreId
            Write-WinUtilJobProgress -Status "Installed $($app.Content) ($position/$totalPackages)" -Percent ([int](($position / $totalPackages) * 100))
        }
    }
}
