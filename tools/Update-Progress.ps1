# Update-Progress.ps1

function Update-Progress {
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$StatusMessage,

        [Parameter(Mandatory, Position = 1)]
        [ValidateRange(0, 100)]
        [int]$Percent,

        [Parameter(Position = 2)]
        [string]$Activity,

        [Parameter(Position = 3)]
        [switch]$LogProgress
    )

    # Default activity to "Processing" if not provided
    if (-not $Activity) {
        $Activity = "Processing"
    }

    # Write the progress to the console
    Write-Progress -Activity $Activity -Status $StatusMessage -PercentComplete $Percent

    # Optionally log the progress to a file
    if ($LogProgress) {
        $logMessage = "{0:yyyy-MM-dd HH:mm:ss} - {1} - {2}% - {3}" -f (Get-Date), $Activity, $Percent, $StatusMessage
        $logMessage | Out-File -FilePath "$PSScriptRoot\progress.log" -Append -Encoding utf8
    }
}

# Example Usage:
# Update-Progress "Processing files..." 50 "File Processing" -LogProgress
