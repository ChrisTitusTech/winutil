function Invoke-WinUtilTweaks ($CheckBox, $undo) {
    $tweak = $sync.configs.tweaks.$CheckBox

    $keys = if ($undo) {
        @{ Registry = "OriginalValue"; Service = "OriginalType"; ScriptType = "UndoScript" }
    } else {
        @{ Registry = "Value"; Service = "StartupType"; OriginalService = "OriginalType"; ScriptType = "InvokeScript" }
    }

    foreach ($svc in $tweak.service) {
        Write-Host "Setting Service $svc.Name to $svc.($keys.Service)"
        Set-Service -Name $svc.Name -StartupType $svc.($keys.Service)
    }

    foreach ($reg in $tweak.registry) {
        Set-WinUtilRegistry -Name $reg.Name -Path $reg.Path -Type $reg.Type -Value $reg.($keys.Registry)
    }

    foreach ($script in $tweak.($keys.ScriptType)) {
        Invoke-WinUtilScript -ScriptBlock ([scriptblock]::Create($script)) -Name $CheckBox
    }

    if (-not $undo) {
        foreach ($app in $tweak.appx) {
            Write-Host "Removing $app"
            Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers
        }
    }
}
