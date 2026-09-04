Write-Host @"
    CCCCCCCCCCCCCTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
 CCC::::::::::::CT:::::::::::::::::::::TT:::::::::::::::::::::T
CC:::::::::::::::CT:::::::::::::::::::::TT:::::::::::::::::::::T
C:::::CCCCCCCC::::CT:::::TT:::::::TT:::::TT:::::TT:::::::TT:::::T
C:::::C       CCCCCCTTTTTT  T:::::T  TTTTTTTTTTTT  T:::::T  TTTTTT
C:::::C                     T:::::T                T:::::T
C:::::C                     T:::::T                T:::::T
C:::::C                     T:::::T                T:::::T
C:::::C                     T:::::T                T:::::T
C:::::C                     T:::::T                T:::::T
C:::::C                     T:::::T                T:::::T
C:::::C       CCCCCC        T:::::T                T:::::T
C:::::CCCCCCCC::::C      TT:::::::TT            TT:::::::TT
CC:::::::::::::::C       T:::::::::T            T:::::::::T
CCC::::::::::::C         T:::::::::T            T:::::::::T
  CCCCCCCCCCCCC          TTTTTTTTTTT            TTTTTTTTTTT

====Chris Titus Tech=====
=====Windows Toolbox=====
"@

# Load the configuration files

$sync.configs.applicationsHashtable = @{}
$sync.configs.applications.PSObject.Properties | ForEach-Object {
    $sync.configs.applicationsHashtable[$_.Name] = $_.Value
}

$sync.configs.appxHashtable = @{}
$sync.configs.appx.PSObject.Properties | ForEach-Object {
    $sync.configs.appxHashtable[$_.Name] = $_.Value
}
$sync.preferences.theme = "Auto"
$sync.preferences.packagemanager = "Winget"

function Remove-WinUtilTempScript {
    <#
    .SYNOPSIS
        Removes the temporary script downloaded by windev.ps1.

    .DESCRIPTION
        Deletes the current script only when it is a winutil-*.ps1 file in
        the system temporary directory. This preserves normal file-backed
        and in-memory WinUtil launches.
    #>

    $scriptPath = $PSCommandPath
    $tempPath = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')

    if (
        $scriptPath -and
        [IO.Path]::GetDirectoryName($scriptPath) -eq $tempPath -and
        [IO.Path]::GetFileName($scriptPath) -like 'winutil-*.ps1'
    ) {
        Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue
    }
}

#===========================================================================
# Headless runs never build a window
#===========================================================================

if ($Preset -or $Config) {
    $headlessCode = 1
    try {
        Initialize-WinUtilRunspacePool | Out-Null

        if ($Preset) {
            if (-not $sync.configs.preset.$Preset) {
                throw "There is no preset called '$Preset'. Available: $(($sync.configs.preset.PSObject.Properties.Name) -join ', ')"
            }
            Write-WinUtilLog -Component "AutoRun" -Message "Applying preset '$Preset'."
            # SkipUnknown so a retired entry in a preset is named and stepped over rather than
            # ending a headless run that has nobody to read the error
            $skipped = @(Update-WinUtilSelections -flatJson $sync.configs.preset.$Preset -SkipUnknown)
            if ($skipped.Count -gt 0) {
                Write-WinUtilLog -Level "WARN" -Component "AutoRun" -Message "Preset '$Preset' names $($skipped.Count) entr(y/ies) this version does not have: $($skipped -join ', ')"
            }
        }

        # Both may be given: the preset sets a baseline and the config adds to it
        if ($Config) {
            Write-WinUtilLog -Component "AutoRun" -Message "Importing selections from '$Config'."
            Invoke-WPFImpex -type "import" -Config $Config -Merge:([bool]$Preset) -ThrowOnError
        }

        $summary = Invoke-WinUtilAutoRun
        $headlessCode = Write-WinUtilAutoRunSummary -Summary $summary
    } catch {
        Write-WinUtilErrorRecord -ErrorRecord $_ -Component "AutoRun" -Context "Headless run"
        Write-Host "WinUtil could not complete the headless run: $($_.Exception.Message)" -ForegroundColor Red
        $headlessCode = 1
    } finally {
        Close-WinUtilRunspacePool
        [System.GC]::Collect()
        Remove-WinUtilTempScript
        Stop-Transcript | Out-Null
    }

    # An isolated elevated child and an explicit file launch own their process. The documented
    # in-memory invocation runs inside the caller's terminal and must return without closing it.
    if ($env:WINUTIL_HEADLESS_CHILD -eq "1" -or $script:WinUtilIsFileProcess) {
        exit $headlessCode
    }
    $global:LASTEXITCODE = $headlessCode
    return $headlessCode
}

#===========================================================================
# Start the interface on its own thread and manage it from here
#===========================================================================
#
# The main thread stays out of the window's way. It creates the dedicated STA runspace the
# interface lives on, waits for that window to close, and reports anything the interface
# thread failed with. Work started from the interface goes to the worker pool through
# Start-WinUtilJob, so neither the window nor this thread is ever blocked by it.

$sync.UIRunspace = [runspacefactory]::CreateRunspace($Host, (New-WinUtilSessionState))
$sync.UIRunspace.ApartmentState = "STA"
$sync.UIRunspace.ThreadOptions = "ReuseThread"
$sync.UIRunspace.Open()

$uiShell = [powershell]::Create()
$uiShell.Runspace = $sync.UIRunspace
[void]$uiShell.AddScript({ Start-WinUtilUserInterface })

Write-WinUtilLog -Component "UI" -Message "Starting the interface thread."
$uiHandle = $uiShell.BeginInvoke()

# This thread has nothing to do but wait, so it pays for the overlay render rather than
# leaving it to the thread that is building the window
Start-WinUtilAssetRendering | Out-Null

$uiHandle.AsyncWaitHandle.WaitOne() | Out-Null

$uiFailed = $false
try {
    $uiShell.EndInvoke($uiHandle) | Out-Null
} catch {
    $uiFailed = $true
    Write-WinUtilErrorRecord -ErrorRecord $_ -Component "UI" -Context "Interface thread stopped"
}

foreach ($uiWarning in $uiShell.Streams.Warning) {
    Write-WinUtilLog -Level "WARN" -Component "UI" -Message $uiWarning.Message
}

foreach ($uiError in $uiShell.Streams.Error) {
    Write-WinUtilErrorRecord -ErrorRecord $uiError -Component "UI" -Context "Interface thread"
}

$uiShell.Dispose()
$sync.UIRunspace.Dispose()
$sync.Remove("UIRunspace")

# The window may have been closed over a job that the user chose to let finish. It is still on
# the worker pool, so the pool cannot be closed until it is done.
Wait-WinUtilRemainingWork

Close-WinUtilRunspacePool
[System.GC]::Collect()

Remove-WinUtilTempScript
Write-Host "Bye bye!" -ForegroundColor Cyan
Stop-Transcript

if ($uiFailed) {
    $global:LASTEXITCODE = 1
    if ($script:WinUtilIsFileProcess) { exit 1 }
    return 1
}
