function Invoke-WPFAppxInstall {
    if ($sync.ProcessRunning) {
        Show-WinUtilMessage -Message "An AppX process is currently running." -Title "WinUtil" -Button "OK" -Icon "Warning"
        return
    }

    if ($null -eq $sync.selectedAppx -or $sync.selectedAppx.Count -eq 0) {
        Show-WinUtilMessage -Message "No AppX Package selected" -Title "Error" -Button "OK" -Icon "Error"
        return
    }

    $selected = @($sync.selectedAppx)
    $apps = $sync.configs.appxHashtable

    Invoke-WPFRunspace -ParameterList @(("selected", $selected), ("apps", $apps)) -ScriptBlock {
        param($selected, $apps)

        $sync.ProcessRunning = $true
        $totalPackages = @($selected).Count
        Write-WinUtilLog -Component "AppX" -Message "Starting AppX install for $totalPackages selected package(s)."
        Set-WinUtilTweaksProgressIndicator -Visible $true -Label "Preparing AppX install (0/$totalPackages)" -Percent 0
        Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state "Normal" -value 0.01 -overlay "logo" }

        try {
            for ($index = 0; $index -lt $totalPackages; $index++) {
                $key = $selected[$index]
                $app = $apps[$key]
                $position = $index + 1
                $startPercent = [int](($index / $totalPackages) * 100)

                Set-WinUtilTweaksProgressIndicator -Visible $true -Label "Installing $($app.Content) ($position/$totalPackages)" -Percent $startPercent
                Write-Host "Installing $($app.Content)"
                Install-WinUtilAPPX -Name $app.PackageId -StoreId $app.StoreId

                $completedPercent = [int](($position / $totalPackages) * 100)
                Set-WinUtilTweaksProgressIndicator -Visible $true -Label "Installed $($app.Content) ($position/$totalPackages)" -Percent $completedPercent
                Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -value ($completedPercent / 100) }
            }

            Write-Host "================================="
            Write-Host "--   AppX Install Finished   ---"
            Write-Host "================================="
            Write-WinUtilLog -Component "AppX" -Message "AppX install finished."
            Set-WinUtilTweaksProgressIndicator -Visible $true -Label "AppX install finished" -Percent 100
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" }
        }
        catch {
            Write-WinUtilLog -Level "ERROR" -Component "AppX" -Message "AppX install failed: $($_.Exception.Message)"
            Set-WinUtilTweaksProgressIndicator -Visible $true -Label "AppX install failed" -Percent 100
            Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state "Error" -overlay "warning" }
        }
        finally {
            $sync.ProcessRunning = $false
        }
    }
}
