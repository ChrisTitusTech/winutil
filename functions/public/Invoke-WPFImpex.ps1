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
            $Config = ConfigDialog
            if ($Config) {
                $jsonFile = Get-WinUtilCheckBoxes -unCheck $false | ConvertTo-Json
                $jsonFile | Out-File $Config -Force
                "iex ""& { `$(irm christitus.com/win) } -Config '$Config'""" | Set-Clipboard
            }
        }
        "import" {
            $Config = ConfigDialog
            if ($Config) {
                if ($Config -match '^https?://') {
                    $jsonFile = (Invoke-WebRequest "$Config").Content | ConvertFrom-Json
                } else {
                    $jsonFile = Get-Content $Config | ConvertFrom-Json
                }
                $flattenedJson = $jsonFile.PSObject.Properties.Where({ $_.Name -ne "Install" }).ForEach({ $_.Value })
                Invoke-WPFPresets -preset $flattenedJson -imported $true
            }
        }
    }
}
