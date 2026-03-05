function Set-WinUtilScheduledTask {
    <#

    .SYNOPSIS
        Enables/Disables the provided Scheduled Task

    .PARAMETER Name
        The path to the Scheduled Task

    .PARAMETER State
        The State to set the Task to

    .EXAMPLE
        Set-WinUtilScheduledTask -Name "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" -State "Disabled"

    #>
    param (
        $Name,
        $State
    )

    try {
        if($State -eq "Disabled") {
            Write-Host "Disabling Scheduled Task $Name"
            Disable-ScheduledTask -TaskName $Name -ErrorAction Stop
        }
        if($State -eq "Enabled") {
            Write-Host "Enabling Scheduled Task $Name"
            Enable-ScheduledTask -TaskName $Name -ErrorAction Stop
        }
    } catch [System.Exception] {
        if ($_.Exception -and $_.Exception.Message -like "*The system cannot find the file specified*") {
            Write-Warning "Scheduled Task $name was not Found"
        } else {
            Write-Warning "Unable to set $Name due to unhandled exception"
            if ($_.Exception -and -not [string]::IsNullOrWhiteSpace($_.Exception.Message)) {
                Write-Warning $_.Exception.Message
            }
        }
    } catch {
        Write-Warning "Unable to run script for $name due to unhandled exception"
        if ($_.Exception) {
            if (-not [string]::IsNullOrWhiteSpace($_.Exception.Message)) {
                Write-Warning $_.Exception.Message
            }
            if (-not [string]::IsNullOrWhiteSpace($_.Exception.StackTrace)) {
                Write-Warning $_.Exception.StackTrace
            }
        }
    }
}
