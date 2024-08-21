# Update-Progress.ps1

function Update-Progress {
    <#
    .SYNOPSIS
    A wrapper for PowerShell 'Write-Progress' Cmdlet.

    .PARAMETER StatusMessage
    A mandatory parameter which’ll be used when displaying progress bar using 'Write-Progress' Cmdlet.

    .PARAMETER Percent
    An integer value (0-100) representing the completion percentage.

    .PARAMETER Activity
    The activity name to be displayed in the progress bar. Defaults to "Processing" if not provided.

    .PARAMETER LogProgress
    A switch that indicates whether the progress should be logged to a file.

    .EXAMPLE
    Update-Progress "Processing files..." 50 "File Processing" -LogProgress
    #>

    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$StatusMessage,

        [Parameter(Position = 1)]
        [ValidateRange(0, 100)]
        [int]$Percent,

        [Parameter(Position = 2)]
        [string]$Activity = "Processing",  # Default activity to "Processing" if not provided

        [Parameter(Position = 3)]
        [switch]$LogProgress
    )

    # Write the progress to the console
    Write-Progress -Activity $Activity -Status $StatusMessage -PercentComplete $Percent

    # Optionally log the progress to a file
    if ($LogProgress) {
        $logMessage = "{0:yyyy-MM-dd HH:mm:ss} - {1} - {2}% - {3}" -f (Get-Date), $Activity, $Percent, $StatusMessage
        $logMessage | Out-File -FilePath "$PSScriptRoot\progress.log" -Append -Encoding utf8
    }
}
