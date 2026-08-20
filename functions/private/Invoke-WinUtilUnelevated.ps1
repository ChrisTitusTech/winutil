function Invoke-WinUtilUnelevated {
    <#
        .SYNOPSIS
            Runs a command as the signed in user, without elevation, and reports what it did

        .DESCRIPTION
            WinUtil runs elevated, and WinGet refuses to touch a package that was installed in
            user scope from an administrator context: it answers
            APPINSTALLER_CLI_ERROR_ADMIN_CONTEXT_ACTION_PROHIBITED and does nothing.

            A process cannot drop its own elevation, so the work is handed to a scheduled task
            registered to run as the interactive user at limited run level, which is the context
            that user's own shell has. The task is removed again whatever happens.

            The command is written to a script file rather than pushed through the task's
            argument string, so paths and arguments with spaces or quotes survive intact.

        .PARAMETER FilePath
            The executable to run.

        .PARAMETER ArgumentList
            Its arguments, one per element.

        .PARAMETER TimeoutSeconds
            How long to let it run before giving up on it.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [string[]]$ArgumentList = @(),

        [int]$TimeoutSeconds = 1800
    )

    $taskName = "WinUtil_Unelevated_$([guid]::NewGuid().ToString('N').Substring(0, 12))"
    $workDir = Join-Path ([IO.Path]::GetTempPath()) $taskName
    $null = New-Item -ItemType Directory -Path $workDir -Force

    try {
        $scriptPath = Join-Path $workDir "run.ps1"
        $outputPath = Join-Path $workDir "output.txt"

        $quotedArgs = @($ArgumentList | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }) -join ', '
        $quotedFile = $FilePath -replace "'", "''"
        $quotedOut = $outputPath -replace "'", "''"

        # The exit code is what the caller acts on, so it is passed back through the task's own
        # result rather than parsed out of the output
        Set-Content -Path $scriptPath -Encoding UTF8 -Value @"
`$ErrorActionPreference = 'Continue'
`$commandArgs = @($quotedArgs)
& '$quotedFile' @commandArgs *>&1 | Out-File -FilePath '$quotedOut' -Encoding utf8
exit `$LASTEXITCODE
"@

        $action = New-ScheduledTaskAction -Execute "powershell.exe" `
            -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$scriptPath`""
        $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([timespan]::FromSeconds($TimeoutSeconds))

        $null = Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings -Force
        $null = Start-ScheduledTask -TaskName $taskName

        $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
        do {
            Start-Sleep -Milliseconds 400
            $state = (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue).State
        } while ($state -eq "Running" -and (Get-Date) -lt $deadline)

        if ($state -eq "Running") {
            $null = Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
            return [pscustomobject]@{
                ExitCode = -1
                Output = "The command did not finish within $TimeoutSeconds seconds."
                TimedOut = $true
            }
        }

        $exitCode = (Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue).LastTaskResult
        $output = if (Test-Path $outputPath) { Get-Content -Path $outputPath -Raw } else { "" }

        return [pscustomobject]@{
            ExitCode = [int]$exitCode
            Output = $output
            TimedOut = $false
        }
    } finally {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
