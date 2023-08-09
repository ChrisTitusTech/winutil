function Set-WinUtilRestorePoint {
    <#
    
        .DESCRIPTION
        This function will make a Restore Point

    #>    

    # Check if the user has administrative privileges
    if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Please run this script as an administrator."
        return
    }

    # Check if System Restore is enabled for the main drive
    try {
        # Try getting restore points to check if System Restore is enabled
        Enable-ComputerRestore -Drive "$env:SystemDrive"
    } catch {
        Write-Host "An error occurred while enabling System Restore: $_"
    }

    # Get all the restore points for the current day
    $existingRestorePoints = Get-ComputerRestorePoint | Where-Object { $_.CreationTime.Date -eq (Get-Date).Date }

    # Check if there is already a restore point created today
    if ($existingRestorePoints.Count -eq 0) {
        $description = "System Restore Point created by WinUtil"
        
        Checkpoint-Computer -Description $description -RestorePointType "MODIFY_SETTINGS"
        Write-Host -ForegroundColor Green "System Restore Point Created Successfully"
    }
}
