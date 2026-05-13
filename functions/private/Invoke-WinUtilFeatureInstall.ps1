function Invoke-WinUtilFeatureInstall ($CheckBox) {

    if ($sync.configs.feature.$CheckBox.feature) {
        foreach ($feature in $sync.configs.feature.$CheckBox.feature) {
            Write-Host "Installing $feature"
            Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart -ErrorAction Stop
        }
    }

    if ($sync.configs.feature.$CheckBox.InvokeScript) {
        foreach ($script in $sync.configs.feature.$CheckBox.InvokeScript) {
            Write-Host "Running Script for $CheckBox"
            Invoke-Command -ScriptBlock ([scriptblock]::Create($script)) -ErrorAction Stop
        }
    }
}
