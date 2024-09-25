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

    if ($type -eq "export") {
        $FileBrowser = New-Object System.Windows.Forms.SaveFileDialog
    }
    if ($type -eq "import") {
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
    }

    if (-not $Config) {
        $FileBrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop')
        $FileBrowser.Filter = "JSON Files (*.json)|*.json"
        $FileBrowser.ShowDialog() | Out-Null

        if($FileBrowser.FileName -eq "") {
            return
        } else {
            $Config = $FileBrowser.FileName
        }
    }

    if ($type -eq "export") {
        $jsonFile = Get-WinUtilCheckBoxes -unCheck $false
        $jsonFile | ConvertTo-Json | Out-File $FileBrowser.FileName -Force
        $runscript = "iex ""& { `$(irm christitus.com/win) } -Config '$($FileBrowser.FileName)'"""
        $runscript | Set-Clipboard
    }
    if ($type -eq "import") {
        $jsonFile = Get-Content $Config | ConvertFrom-Json

        $flattenedJson = @()
        $jsonFile.PSObject.Properties | ForEach-Object {
            $category = $_.Name
            foreach ($checkboxName in $_.Value) {
                if ($category -ne "Install") {
                    $flattenedJson += $checkboxName
                }
            }
        }

        Invoke-WPFPresets -preset $flattenedJson -imported $true
    }
}
