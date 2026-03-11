function Invoke-WPFImpex {
    param(
        $type,
        $Config = $null
    )

    function ConfigDialog {
        if (!$Config) {
            switch ($type) {
                "export" { $FileBrowser = New-Object System.Windows.Forms.SaveFileDialog }
                "import" { $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog }
            }

            $FileBrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop')
            $FileBrowser.Filter = "JSON Files (*.json)|*.json"
            $FileBrowser.ShowDialog() | Out-Null

            if ($FileBrowser.FileName -eq "") {
                return $null
            } else {
                return $FileBrowser.FileName
            }
        } else {
            return $Config
        }
    }

    switch ($type) {
        "export" {
            try {
                $Config = ConfigDialog
                if ($Config) {
                    $allConfs = ($sync.selectedApps + $sync.selectedTweaks + $sync.selectedToggles + $sync.selectedFeatures) | ForEach-Object { [string]$_ }

                    if (-not $allConfs) {
                        [System.Windows.MessageBox]::Show(
                            "No settings are selected to export. Please select at least one app, tweak, toggle, or feature before exporting.",
                            "Nothing to Export", "OK", "Warning")
                        return
                    }

                    $jsonFile = $allConfs | ConvertTo-Json
                    $jsonFile | Out-File $Config -Force
                    "iex ""& { `$(irm https://christitus.com/win) } -Config '$Config'""" | Set-Clipboard
                }
            } catch {
                Write-Error "An error occurred while exporting: $_"
            }
        }

        "import" {
            try {
                $Config = ConfigDialog
                if ($Config) {

                    try {
                        if ($Config -match '^https?://') {
                            $jsonFile = (Invoke-WebRequest "$Config").Content | ConvertFrom-Json
                        } else {
                            $jsonFile = Get-Content $Config -Raw | ConvertFrom-Json
                        }
                    } catch {
                        Write-Error "Failed to load the JSON file from the specified path or URL: $_"
                        return
                    }

                    # Normalize single string to array
                    if ($jsonFile -is [string]) {
                        $flattenedJson = @($jsonFile)
                    } else {
                        $flattenedJson = @($jsonFile)
                    }

                    # Remove empty/null and keep only valid keys in $sync
                    $flattenedJson = $flattenedJson |
                        Where-Object { $_ -and $_.ToString().Trim() -ne "" } |
                        Where-Object { $sync.PSObject.Properties.Name -contains $_ }

                    if (-not $flattenedJson) {
                        [System.Windows.MessageBox]::Show(
                            "The selected file contains no settings to import. No changes have been made.",
                            "Empty Configuration", "OK", "Warning")
                        return
                    }

                    $sync.selectedApps = [System.Collections.Generic.List[string]]::new()
                    $sync.selectedTweaks = [System.Collections.Generic.List[string]]::new()
                    $sync.selectedToggles = [System.Collections.Generic.List[string]]::new()
                    $sync.selectedFeatures = [System.Collections.Generic.List[string]]::new()

                    Update-WinUtilSelections -flatJson $flattenedJson

                    if (!$PARAM_NOUI) {
                        Reset-WPFCheckBoxes -doToggles $true
                    }
                }
            } catch {
                Write-Error "An error occurred while importing: $_"
            }
        }
    }
}
