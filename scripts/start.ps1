<#
.NOTES
    Author         : Chris Titus @christitustech
    Runspace Author: @DeveloperDurp
    GitHub         : https://github.com/ChrisTitusTech
    Version        : #{replaceme}
#>

param (
    [string]$Config,
    [ValidateSet("Standard", "Minimal", "Advanced", "")]
    [string]$Preset,
    [switch]$Offline
)

function Test-WinUtilOwnsFileProcess {
    <#
        .SYNOPSIS
            Whether the current process was launched with this script as its file target
    #>
    param(
        [string]$ScriptPath = $PSCommandPath,
        [string[]]$CommandLineArgs = [Environment]::GetCommandLineArgs()
    )

    if ([string]::IsNullOrWhiteSpace($ScriptPath)) { return $false }

    $hostOptionKinds = [ordered]@{
        Command           = "Command"
        EncodedCommand    = "Command"
        CommandWithArgs   = "Command"
        File              = "File"
        ConfigurationFile = "Value"
        ConfigurationName = "Value"
        CustomPipeName    = "Value"
        ExecutionPolicy   = "Value"
        InputFormat       = "Value"
        Interactive       = "Switch"
        Login             = "Switch"
        MTA               = "Switch"
        NoLogo            = "Switch"
        NonInteractive    = "Switch"
        NoProfile         = "Switch"
        NoProfileLoadTime = "Switch"
        OutputFormat      = "Value"
        PSConsoleFile     = "Value"
        SettingsFile      = "Value"
        SSHServerMode     = "Switch"
        STA               = "Switch"
        Version           = "Value"
        WindowStyle       = "Value"
        WorkingDirectory  = "Value"
        NoExit            = "NoExit"
    }
    $hostOptionAliases = @{
        c = "Command"; cwa = "Command"; e = "Command"; ec = "Command"; f = "File"
        noe = "NoExit"
        config = "Value"; ConfigName = "Value"; CustomPipe = "Value"; ep = "Value"; ex = "Value"
        i = "Switch"; Input = "Value"; In = "Value"; if = "Value"
        Output = "Value"; Out = "Value"; of = "Value"
        Settings = "Value"; Window = "Value"; w = "Value"; Working = "Value"; wd = "Value"
    }

    function Get-WinUtilHostOptionKind {
        param([string]$Argument)

        if ([string]::IsNullOrWhiteSpace($Argument) -or -not $Argument.StartsWith("-")) {
            return $null
        }

        $optionName = $Argument.TrimStart("-")
        if ($hostOptionAliases.ContainsKey($optionName)) {
            return $hostOptionAliases[$optionName]
        }

        # pwsh accepts any unambiguous prefix of a host option, such as -WorkingD.
        $matchingOptions = @($hostOptionKinds.Keys | Where-Object {
            $_.StartsWith($optionName, [StringComparison]::OrdinalIgnoreCase)
        })
        $matchingKinds = @($matchingOptions | ForEach-Object { $hostOptionKinds[$_] } | Select-Object -Unique)
        if ($matchingKinds.Count -eq 1) {
            return $matchingKinds[0]
        }

        return $null
    }

    :hostArguments for ($index = 1; $index -lt $CommandLineArgs.Count; $index++) {
        $optionKind = Get-WinUtilHostOptionKind -Argument $CommandLineArgs[$index]
        switch ($optionKind) {
            "Command" { return $false }
            "NoExit" { return $false }
            "Switch" { continue hostArguments }
            "File" {
                if ($index + 1 -ge $CommandLineArgs.Count) { return $false }
                $fileTarget = $CommandLineArgs[$index + 1]
                if ([string]::IsNullOrWhiteSpace($fileTarget) -or $fileTarget -eq "-") {
                    return $false
                }

                return [string]::Equals(
                    [IO.Path]::GetFullPath($fileTarget),
                    [IO.Path]::GetFullPath($ScriptPath),
                    [StringComparison]::OrdinalIgnoreCase
                )
            }
            "Value" {
                $index++
                continue hostArguments
            }
        }

        if ($CommandLineArgs[$index].StartsWith("-")) {
            continue
        }

        return [string]::Equals(
            [IO.Path]::GetFullPath($CommandLineArgs[$index]),
            [IO.Path]::GetFullPath($ScriptPath),
            [StringComparison]::OrdinalIgnoreCase
        )
    }

    return $false
}

# A headless script launched with powershell.exe/pwsh.exe -File owns its process and must set
# that process's exit code. An invoked or in-memory script must return without closing its caller.
$script:WinUtilIsFileProcess = Test-WinUtilOwnsFileProcess

$PARAM_OFFLINE = $false
if ($Offline) {
    $PARAM_OFFLINE = $true
}

if ($ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') {
    Write-Host "WinUtil is unable to run on your system. PowerShell execution is restricted by security policies." -ForegroundColor Red
    $global:LASTEXITCODE = 1
    if ($env:WINUTIL_HEADLESS_CHILD -eq "1" -or $script:WinUtilIsFileProcess) { exit 1 }
    return 1
}

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "WinUtil needs to be run as Administrator. Attempting to relaunch."
    $argList = @()

    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        $argList += if ($_.Value -is [switch] -and $_.Value) {
            "-$($_.Key)"
        } elseif ($_.Value -is [array]) {
            "-$($_.Key) $($_.Value -join ',')"
        } elseif ($_.Value) {
            "-$($_.Key) '$($_.Value)'"
        }
    }

    $script = if ($PSCommandPath) {
        "& { & `'$($PSCommandPath)`' $($argList -join ' ') }"
    } else {
        "&([ScriptBlock]::Create((irm https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1))) $($argList -join ' ')"
    }

    $powershellCmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }

    # A headless caller is waiting on this process for an outcome, so the elevated run has to be
    # waited on and its code handed back. A terminal tab is skipped for the same reason: the
    # exit code of wt.exe is its own, not the run's.
    if ($Config -or $Preset) {
        # A declined UAC prompt throws, which would leave $elevated null and exit 0: the caller
        # waiting on this process would read that as a successful run
        try {
            $headlessScript = "`$env:WINUTIL_HEADLESS_CHILD = '1'; $script"
            $elevated = Start-Process $powershellCmd -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"$headlessScript`"" -Verb RunAs -Wait -PassThru -ErrorAction Stop
        } catch {
            Write-Host "Elevation was declined or failed: $($_.Exception.Message)" -ForegroundColor Red
            $global:LASTEXITCODE = 1
            if ($script:WinUtilIsFileProcess) { exit 1 }
            return 1
        }
        $global:LASTEXITCODE = $elevated.ExitCode
        if ($script:WinUtilIsFileProcess) { exit $elevated.ExitCode }
        return $elevated.ExitCode
    }

    $processCmd = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { "$powershellCmd" }

    if ($processCmd -eq "wt.exe") {
        Start-Process $processCmd -ArgumentList "$powershellCmd -ExecutionPolicy Bypass -NoProfile -Command `"$script`"" -Verb RunAs
    } else {
        Start-Process $processCmd -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"$script`"" -Verb RunAs
    }

    break
}

# Variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.version = "#{replaceme}"
$sync.configs = @{}
$sync.Buttons = [System.Collections.Generic.List[PSObject]]::new()
$sync.preferences = @{}
# Name of the job currently running, or $null when idle. Owned by Start-WinUtilJob.
$sync.ActiveJob = $null
# Serializes worker-pool startup with recycling and shutdown.
$sync.RunspacePoolLock = [object]::new()
# Serializes the speculative and UI-thread taskbar overlay renderers.
$sync.AssetRenderLock = [object]::new()
$sync.RenderedAssetCache = [Hashtable]::Synchronized(@{})
# Every step recorded by Measure-WinUtilStep, from any thread
$sync.StepTimings = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
# Every error logged, so a job can report that something went wrong even when it did not throw
$sync.LoggedErrors = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
$sync.StartedAt = Get-Date
$sync.selectedAppx = [System.Collections.Generic.List[string]]::new()
$sync.selectedApps = [System.Collections.Generic.List[string]]::new()
$sync.selectedTweaks = [System.Collections.Generic.List[string]]::new()
$sync.selectedToggles = [System.Collections.Generic.List[string]]::new()
$sync.selectedFeatures = [System.Collections.Generic.List[string]]::new()
$sync.currentTab = "Install"

$dateTime = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$winutildir = "$env:LocalAppData\winutil"
$sync.winutildir = $winutildir

$logdir = "$winutildir\logs"
# Start-Transcript fails outright when the directory is missing, which is every first run
if (-not (Test-Path $logdir)) {
    New-Item -ItemType Directory -Path $logdir -Force | Out-Null
}
# Keep console output and structured entries in the path reported to the user. Write-WinUtilLog
# writes through the host while this transcript owns the file, avoiding competing file handles.
$sync.logPath = "$logdir\winutil_$dateTime.log"
$sync.transcriptPath = $sync.logPath
Start-Transcript -Path $sync.transcriptPath -Append -NoClobber | Out-Null

$Host.UI.RawUI.WindowTitle = "WinUtil"
Clear-Host
