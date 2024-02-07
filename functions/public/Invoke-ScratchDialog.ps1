
function Invoke-ScratchDialog {

    <#

    .SYNOPSIS
        Enable Editable Text box Alternate Scartch path

    .PARAMETER Button
    #>
    $sync.WPFMicrowinISOScratchDir.IsChecked 
 

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $Dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $Dialog.SelectedPath =          $sync.MicrowinScratchDirBox.Text
    $Dialog.ShowDialog() 
    $filePath = $Dialog.SelectedPath
        Write-Host "No ISO is chosen+  $filePath"

    if ([string]::IsNullOrEmpty($filePath))
    {
        Write-Host "No Folder had chosen"
        return
    }
    
       $sync.MicrowinScratchDirBox.Text =  Join-Path $filePath "\"

}
