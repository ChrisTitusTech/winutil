function Invoke-WinUtilWinGetCommand {
    <#
        .SYNOPSIS
            Runs a Microsoft.WinGet.Client command and reports its progress as it goes

        .DESCRIPTION
            The module reports progress through the PowerShell progress stream, which cannot be
            redirected like output or errors. Running the command on a nested PowerShell
            instance makes that stream readable, so download and install percentages can be
            polled while the command is still running.

        .PARAMETER Command
            The cmdlet to run, for example Install-WinGetPackage.

        .PARAMETER Parameters
            Arguments for the cmdlet.

        .PARAMETER ProgressBase
            Where this command starts within the job's overall progress bar.

        .PARAMETER ProgressSpan
            How much of the overall bar this command accounts for. Zero reports nothing.

        .PARAMETER Label
            Text shown before the module's own status, normally the package name.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [hashtable]$Parameters = @{},

        [int]$ProgressBase = 0,

        [int]$ProgressSpan = 0,

        [string]$Label
    )

    $shell = [powershell]::Create()
    try {
        [void]$shell.AddCommand("Import-Module").AddParameter("Name", "Microsoft.WinGet.Client")
        [void]$shell.AddStatement().AddCommand($Command)
        foreach ($entry in $Parameters.GetEnumerator()) {
            [void]$shell.AddParameter($entry.Key, $entry.Value)
        }

        $handle = $shell.BeginInvoke()

        $reported = ""
        while (-not $handle.IsCompleted) {
            $latest = @($shell.Streams.Progress)[-1]
            if ($latest) {
                $status = if ($Label) { "$Label - $($latest.StatusDescription)" } else { $latest.StatusDescription }
                # The module uses -1 for phases it cannot measure, such as post-install
                if ($latest.PercentComplete -ge 0 -and $ProgressSpan -gt 0) {
                    $percent = $ProgressBase + [int](($latest.PercentComplete / 100) * $ProgressSpan)
                    Write-WinUtilJobProgress -Status $status -Percent $percent
                } elseif ($status -ne $reported) {
                    Write-WinUtilJobProgress -Status $status
                }
                $reported = $status
            }
            Start-Sleep -Milliseconds 150
        }

        $output = $shell.EndInvoke($handle)

        foreach ($record in $shell.Streams.Error) {
            Write-WinUtilErrorRecord -ErrorRecord $record -Component "Package" -Context $Command
        }
        foreach ($record in $shell.Streams.Warning) {
            Write-WinUtilLog -Level "WARN" -Component "Package" -Message $record.Message
        }

        return @($output)
    } finally {
        $shell.Dispose()
    }
}
