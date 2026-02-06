function Invoke-AutoConfigDialog {

    <#
        .SYNOPSIS
            Sets the automatic configuration file based on a specified JSON file
    #>

    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    $OFD = New-Object System.Windows.Forms.OpenFileDialog
    $OFD.Filter = "JSON Files (*.json)|*.json"
    $OFD.ShowDialog()

    if ($OFD.FileName -eq "")
    {
        Write-Host "No automatic config file has been selected. Continuing without one..."
        return
    }

    return $OFD.FileName
}
