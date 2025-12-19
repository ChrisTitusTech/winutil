function Invoke-WPFImpex {
    <#

    .SYNOPSIS
        Handles importing and exporting of the checkboxes checked for the tweaks section

    .PARAMETER type
        Indicates whether to 'import' or 'export'

    .PARAMETER checkbox
        The checkbox to export to a file or apply the imported file to

    .EXAMPLE
        Invoke-WPFImpex -type "export"

    #>
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

            $userConfigPath = Join-Path $env:LOCALAPPDATA "Winutil\user_config.json"
            $initialDir = [Environment]::GetFolderPath('Desktop')

            if (Test-Path $userConfigPath) {
                try {
                    $userConfig = Get-Content $userConfigPath | ConvertFrom-Json
                    if ($userConfig.LastImportExportPath -and (Test-Path $userConfig.LastImportExportPath)) {
                        $initialDir = $userConfig.LastImportExportPath
                    }
                } catch {
                    # Ignore errors reading config
                }
            }

            $FileBrowser.InitialDirectory = $initialDir
            $FileBrowser.Filter = "JSON Files (*.json)|*.json"
            $FileBrowser.ShowDialog() | Out-Null

            if ($FileBrowser.FileName -eq "") {
                return $null
            } else {
                try {
                    $selectedDir = Split-Path $FileBrowser.FileName -Parent
                    $configDir = Split-Path $userConfigPath -Parent
                    if (!(Test-Path $configDir)) {
                        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
                    }

                    $configData = @{}
                    if (Test-Path $userConfigPath) {
                        try {
                            $content = Get-Content $userConfigPath -Raw
                            if ($content) {
                                $configData = $content | ConvertFrom-Json
                            }
                        } catch {}
                    }

                    if ($configData -is [PSCustomObject]) {
                        $configData | Add-Member -MemberType NoteProperty -Name "LastImportExportPath" -Value $selectedDir -Force
                    } else {
                        $configData = [PSCustomObject]@{
                            LastImportExportPath = $selectedDir
                        }
                    }

                    $configData | ConvertTo-Json | Out-File $userConfigPath -Force
                } catch {
                    # Ignore errors saving config
                }
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
                    $jsonFile = Get-WinUtilCheckBoxes -unCheck $false | ConvertTo-Json
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
                            $jsonFile = Get-Content $Config | ConvertFrom-Json
                        }
                    } catch {
                        Write-Error "Failed to load the JSON file from the specified path or URL: $_"
                        return
                    }
                    $flattenedJson = $jsonFile.PSObject.Properties.Where({ $_.Name -ne "Install" }).ForEach({ $_.Value })
                    Invoke-WPFPresets -preset $flattenedJson -imported $true
                }
            } catch {
                Write-Error "An error occurred while importing: $_"
            }
        }
    }
}
