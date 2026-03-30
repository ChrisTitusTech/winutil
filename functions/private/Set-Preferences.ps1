function Set-Preferences{

    param(
        [switch]$save=$false
    )

    # TODO delete this function sometime later
    $iniPath = "$winutildir\preferences.ini"

    function Clean-OldPrefs{
        if (Test-Path -Path "$winutildir\LightTheme.ini") {
            $sync.preferences.theme = "Light"
            Remove-Item -Path "$winutildir\LightTheme.ini"
        }

        if (Test-Path -Path "$winutildir\DarkTheme.ini") {
            $sync.preferences.theme = "Dark"
            Remove-Item -Path "$winutildir\DarkTheme.ini"
        }

        # check old prefs, if its first line has no =, then absorb it as pm
        if (Test-Path -Path $iniPath) {
            $oldPM = Get-Content -Path $iniPath -ErrorAction SilentlyContinue
            $firstLine = $oldPM | Select-Object -First 1
            if ($firstLine -and ($firstLine -notlike "*=*")) {
                $sync.preferences.packagemanager = $firstLine
            }
        }

        if (Test-Path -Path "$winutildir\preferChocolatey.ini") {
            $sync.preferences.packagemanager = "Choco"
            Remove-Item -Path "$winutildir\preferChocolatey.ini"
        }
    }

    function Save-Preferences{
        $ini = ""
        if (-not $sync.preferences) { $sync.preferences = @{} }
        foreach($key in $sync.preferences.Keys) {
            $pref = "$($key)=$($sync.preferences.$key)"
            Write-Debug "Saving pref: $($pref)"
            $ini = $ini + $pref + "`r`n"
        }
        $ini | Out-File -FilePath $iniPath -Encoding utf8
    }

    function Load-Preferences{
        Clean-OldPrefs
        if (Test-Path -Path $iniPath) {
            $iniData = Get-Content -Path $iniPath -ErrorAction SilentlyContinue
            foreach ($line in $iniData) {
                if ($line -like "*=*") {
                    $arr = $line -split "=",2
                    $key = $arr[0] -replace "\s",""
                    $value = $arr[1] -replace "\s",""
                    Write-Debug "Preference: Key = '$($key)' Value ='$($value)'"
                    $sync.preferences.$key = $value
                }
            }
        }

        # write defaults in case preferences dont exist
        if ($null -eq $sync.preferences.theme) {
            $sync.preferences.theme = "Auto"
        }
        if ($null -eq $sync.preferences.packagemanager) {
            $sync.preferences.packagemanager = "Winget"
        }
        if ($null -eq $sync.preferences.language) {
            # default to English
            $sync.preferences.language = "en"
        }

        # convert packagemanager to enum
        try {
            if ($sync.preferences.packagemanager -eq "Choco") {
                $sync.preferences.packagemanager = [PackageManagers]::Choco
            }
            elseif ($sync.preferences.packagemanager -eq "Winget") {
                $sync.preferences.packagemanager = [PackageManagers]::Winget
            }
        } catch {
            # PackageManagers enum/type may not be defined in isolated tests — keep string
            Write-Debug "PackageManagers type not available: $_"
        }

        # keep language as simple code (en/es)
        if ($sync.preferences.language -ne $null) {
            $sync.preferences.language = $sync.preferences.language.Substring(0,2).ToLower()
        }
    }

    $iniPath = "$winutildir\preferences.ini"

    if ($save) {
        Save-Preferences
    }
    else {
        Load-Preferences
    }
}
