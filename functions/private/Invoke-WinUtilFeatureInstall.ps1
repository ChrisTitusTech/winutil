function Invoke-WinUtilFeatureInstall ($CheckBox) {
    Write-WinUtilLog -Component "Feature" -Message "Applying feature action: $CheckBox"

    $featureFailed = $false
    if ($sync.configs.feature.$CheckBox.feature) {
        foreach ($feature in $sync.configs.feature.$CheckBox.feature) {
            Write-Host "Installing $feature"
            Write-WinUtilLog -Component "Feature" -Message "Enabling Windows optional feature: $feature"
            try {
                Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart -ErrorAction Stop
                Write-WinUtilLog -Component "Feature" -Message "Enabled Windows optional feature: $feature"
            } catch {
                $featureFailed = $true
                # A feature missing on this edition (e.g. Windows Sandbox on Home) must not
                # abort the remaining selected features
                Write-Warning "Unable to enable feature $feature`: $($_.Exception.Message)"
                Write-WinUtilLog -Level "ERROR" -Component "Feature" -Message "Unable to enable feature $feature`: $($_.Exception.Message)"
            }
        }
    }

    if ($featureFailed) {
        Write-WinUtilLog -Level "WARN" -Component "Feature" -Message "Skipping dependent scripts after an optional feature failed: $CheckBox"
    } elseif ($sync.configs.feature.$CheckBox.InvokeScript) {
        foreach ($script in $sync.configs.feature.$CheckBox.InvokeScript) {
            Write-Host "Running Script for $CheckBox"
            Write-WinUtilLog -Component "Feature" -Message "Running feature script for: $CheckBox"
            Invoke-Command -ScriptBlock ([scriptblock]::Create($script)) -ErrorAction Stop
            Write-WinUtilLog -Component "Feature" -Message "Completed feature script for: $CheckBox"
        }
    }
    Write-WinUtilLog -Component "Feature" -Message "Feature action completed: $CheckBox"
}
