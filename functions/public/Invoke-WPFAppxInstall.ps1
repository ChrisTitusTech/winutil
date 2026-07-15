function Invoke-WPFAppxInstall {
    if ($null -eq $sync.selectedAppx -or $sync.selectedAppx.Count -eq 0) {
        Show-WinUtilMessage -Message "No AppX Package selected" -Title "Error" -Button "OK" -Icon "Error"
        return
    }

    $selected = @($sync.selectedAppx)
    $apps = $sync.configs.appxHashtable

    Invoke-WPFRunspace -ParameterList @(("selected", $selected), ("apps", $apps)) -ScriptBlock {
        param($selected, $apps)

        $sync.ProcessRunning = $true
        Write-WinUtilLog -Component "AppX" -Message "Starting AppX install for $(@($selected).Count) selected package(s)."

        try {
            foreach ($key in $selected) {
                $app = $apps[$key]
                Write-Host "Installing $($app.Content)"
                Install-WinUtilAPPX -Name $app.PackageId -StoreId $app.StoreId
            }

            Write-Host "================================="
            Write-Host "--   AppX Install Finished   ---"
            Write-Host "================================="
            Write-WinUtilLog -Component "AppX" -Message "AppX install finished."
        }
        catch {
            Write-WinUtilLog -Level "ERROR" -Component "AppX" -Message "AppX install failed: $($_.Exception.Message)"
        }
        finally {
            $sync.ProcessRunning = $false
        }
    }
}
