function Invoke-WinUtilLoggedProcess {
    <#
    .SYNOPSIS
        Runs a process and writes its stdout/stderr output to the WinUtil log.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [object]$ArgumentList,

        [string]$Component = "Process",

        [string]$Description = $FilePath
    )

    $stdoutPath = Join-Path ([System.IO.Path]::GetTempPath()) "winutil-$([guid]::NewGuid())-stdout.log"
    $stderrPath = Join-Path ([System.IO.Path]::GetTempPath()) "winutil-$([guid]::NewGuid())-stderr.log"

    try {
        $displayArguments = @($ArgumentList) -join " "
        Write-WinUtilLog -Component $Component -Message "Running $Description`: $FilePath $displayArguments"

        $process = Start-Process `
            -FilePath $FilePath `
            -ArgumentList $ArgumentList `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath

        $outputStreams = @(
            @{
                Path = $stdoutPath
                Level = "INFO"
                Stream = "stdout"
            },
            @{
                Path = $stderrPath
                Level = "WARN"
                Stream = "stderr"
            }
        )

        foreach ($stream in $outputStreams) {
            if (-not (Test-Path -Path $stream.Path)) {
                continue
            }

            Get-Content -Path $stream.Path | ForEach-Object {
                if ([string]::IsNullOrWhiteSpace($_)) {
                    return
                }

                if ($stream.Stream -eq "stderr") {
                    Write-Warning $_
                } else {
                    Write-Host $_
                }

                Write-WinUtilLog -Level $stream.Level -Component $Component -Message "$Description [$($stream.Stream)] $_"
            }
        }

        if ($null -ne $process -and $null -ne $process.ExitCode -and $process.ExitCode -ne 0) {
            Write-WinUtilLog -Level "ERROR" -Component $Component -Message "$Description exited with code $($process.ExitCode)"
        }

        return $process
    } finally {
        Remove-Item -Path $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
}
