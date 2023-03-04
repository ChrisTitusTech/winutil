function Invoke-WPFImpex {
    <#
    
        .DESCRIPTION
        This function handles importing and exporting of the checkboxes checked for the tweaks section

        .EXAMPLE

        Invoke-WPFImpex -type "export"
    
    #>
    param($type)

    if ($type -eq "export"){
        $FileBrowser = New-Object System.Windows.Forms.SaveFileDialog
    }
    if ($type -eq "import"){
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog 
    }

    $FileBrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    $FileBrowser.Filter = "JSON Files (*.json)|*.json"
    $FileBrowser.ShowDialog() | Out-Null

    if($FileBrowser.FileName -eq ""){
        return
    }
    
    if ($type -eq "export"){
        $jsonFile = Get-WinUtilCheckBoxes WPFTweaks -unCheck $false
        $jsonFile | ConvertTo-Json | Out-File $FileBrowser.FileName -Force
    }
    if ($type -eq "import"){
        $jsonFile = Get-Content $FileBrowser.FileName | ConvertFrom-Json
        Invoke-WPFPresets -preset $jsonFile -imported $true
    }
}
