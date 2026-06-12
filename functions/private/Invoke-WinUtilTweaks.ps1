function Invoke-WinUtilTweaks ($CheckBox, $undo) {
    $tweak = $sync.configs.tweaks.$CheckBox

    $keys = if ($undo) {
        @{ Registry = "OriginalValue"; Service = "OriginalType"; ScriptType = "UndoScript" }
    } else {
        @{ Registry = "Value"; Service = "StartupType"; OriginalService = "OriginalType"; ScriptType = "InvokeScript" }
    }

    foreach ($svc in $tweak.service) {
        Write-Host "Setting Service $($svc.Name) to $($svc.$($keys.Service))"
        Set-Service -Name $svc.Name -StartupType $svc.$($keys.Service)
    }

    foreach ($reg in $tweak.registry) {
        $Name = $reg.Name
        $Path = $reg.Path 
        $Type = $reg.Type
        $Value = $reg.($keys.Registry)

        try {
            if (-not (Get-PSDrive -Name HKU)) {
                New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
            }

            if (-not (Test-Path $Path)) {
                Write-Host "$Path was not found. Creating..."
                New-Item -Path $Path -Force -ErrorAction Stop
            }

            if ($Value -ne "<RemoveEntry>") {
                Write-Host "Set $Path\$Name to $Value"
                Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value -Force -ErrorAction Stop
            } else {
                Write-Host "Remove $Path\$Name"
                Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction Stop
            }
        } catch {
            Write-Warning "Unable to set $Name due to unhandled exception."
            Write-Warning $_.Exception.Message
        }
    }

    foreach ($script in $tweak.($keys.ScriptType)) {
        try {
            Write-Host "Running Script for $CheckBox"
            Invoke-Command ([scriptblock]::Create($script)) -ErrorAction Stop
        } catch {
            Write-Warning "Unable to run script for $CheckBox due to unhandled exception."
            Write-Warning $_.Exception.Message
        }
    }

    if (-not $undo) {
        foreach ($appx in $tweak.appx) {
            Write-Host "Removing $appx"
            Get-AppxPackage -Name $appx -AllUsers | Remove-AppxPackage -AllUsers
        }
    }
}
