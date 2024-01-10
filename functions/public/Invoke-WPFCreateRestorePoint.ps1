function Invoke-WPFCreateRestorePoint {
    <#
    .SYNOPSIS
        Enables the ability to create Windows Restore Points
    #>
    
    $restorePointTypes = @("APPLICATION_INSTALL", "MODIFY_SETTINGS", "APPLICATION_UNINSTALL", "DEVICE_DRIVER_INSTALL", "CANCELLED_OPERATION")
    $selectedRestorePointType = $restorePointTypes | Out-GridView -Title "Select Restore Point Type" -PassThru

    if ($selectedRestorePointType) {
        try {
            $restorePointName = "Pre-WinUtil_$selectedRestorePointType"
        
            Checkpoint-Computer -Description $restorePointName -RestorePointType $selectedRestorePointType

            Write-Output "Restore Point '$restorePointName' created successfully."
        }
        catch {
            Write-Output "Error creating restore point: $_.Exception.Message"
        }
    } else {
        Write-Output "No restore point type selected."
    }
}