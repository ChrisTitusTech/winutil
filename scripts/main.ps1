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

if ($Preset) {
    Initialize-WinUtilRunspacePool | Out-Null

    # Selects the tweaks from $Preset varible
    Update-WinUtilSelections -flatJson $sync.configs.preset.$Preset

    # Run tweaks that were selected by Update-WinUtilSelections
    Invoke-WinUtilAutoRun

    # Cleanup and exit
    Close-WinUtilRunspacePool
    [System.GC]::Collect()
    Stop-Transcript
    return
}

if ($Config) {
    Initialize-WinUtilRunspacePool | Out-Null

    Invoke-WPFImpex -type "import" -Config $Config

    Invoke-WinUtilAutoRun

    # Cleanup and exit
    Close-WinUtilRunspacePool
    [System.GC]::Collect()
    Stop-Transcript
    return
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
$uiHandle.AsyncWaitHandle.WaitOne() | Out-Null

try {
    $uiShell.EndInvoke($uiHandle) | Out-Null
} catch {
    Write-Host "The WinUtil interface stopped with an error: $($_.Exception.Message)" -ForegroundColor Red
    Write-WinUtilLog -Level "ERROR" -Component "UI" -Message "Interface thread failed: $($_.Exception.Message)"
}

foreach ($uiError in $uiShell.Streams.Error) {
    Write-Host $uiError -ForegroundColor Red
    Write-WinUtilLog -Level "ERROR" -Component "UI" -Message $uiError
}

$uiShell.Dispose()
$sync.UIRunspace.Dispose()
$sync.Remove("UIRunspace")

Close-WinUtilRunspacePool
[System.GC]::Collect()

Remove-WinUtilTempScript
Stop-Transcript
