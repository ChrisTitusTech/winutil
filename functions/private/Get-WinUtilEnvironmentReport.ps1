function Get-WinUtilEnvironmentReport {
    <#
    .SYNOPSIS
        Collects the allowlisted data used by the WinUtil environment report.
    #>

    $reportWarnings = [System.Collections.Generic.List[string]]::new()

    $windows = [ordered]@{
        edition      = $null
        version      = $null
        buildNumber  = $null
        architecture = $null
    }
    $hardware = [ordered]@{
        cpuModel              = $null
        logicalProcessorCount = $null
        totalMemoryGB         = $null
    }

    try {
        $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $windows.edition = $operatingSystem.Caption
        $windows.version = $operatingSystem.Version
        $windows.buildNumber = $operatingSystem.BuildNumber
        $windows.architecture = $operatingSystem.OSArchitecture

        if ($null -ne $operatingSystem.TotalVisibleMemorySize) {
            $hardware.totalMemoryGB = [math]::Round(([double]$operatingSystem.TotalVisibleMemorySize / 1MB), 2)
        }
    } catch {
        $message = "Failed to collect Windows/memory info from Win32_OperatingSystem: $($_.Exception.Message)"
        Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message $message
        [void]$reportWarnings.Add($message)
    }

    try {
        $processors = @(Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop)
        if ($processors.Count -gt 0) {
            $hardware.cpuModel = $processors[0].Name
            $hardware.logicalProcessorCount = [int](($processors | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum)
        }
    } catch {
        $message = "Failed to collect CPU info from Win32_Processor: $($_.Exception.Message)"
        Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message $message
        [void]$reportWarnings.Add($message)
    }

    $powershell = [ordered]@{
        edition         = $PSVersionTable.PSEdition
        version         = $PSVersionTable.PSVersion.ToString()
        executionPolicy = $null
    }

    try {
        $powershell.executionPolicy = (Get-ExecutionPolicy).ToString()
    } catch {
        $message = "Failed to read PowerShell execution policy: $($_.Exception.Message)"
        Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message $message
        [void]$reportWarnings.Add($message)
    }

    # Re-use built-in functionality
    $chocolatey = [ordered]@{ installed = $false; version = $null }
    try {
        $chocolatey.installed = (Test-WinUtilPackageManager -choco 6>$null) -eq "installed"
    } catch {
        $message = "Failed to check Chocolatey availability: $($_.Exception.Message)"
        Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message $message
        [void]$reportWarnings.Add($message)
    }

    if ($chocolatey.installed) {
        try {
            $global:LASTEXITCODE = 0
            $versionOutput = @(choco -v 2>&1)
            if ($LASTEXITCODE -ne 0) {
                throw "Chocolatey version probe exited with code $LASTEXITCODE."
            }
            $chocolatey.version = ($versionOutput | Select-Object -First 1).ToString().Trim()
        } catch {
            $message = "Failed to read Chocolatey version: $($_.Exception.Message)"
            Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message $message
            [void]$reportWarnings.Add($message)
        }
    }

    $winget = [ordered]@{ installed = $false; version = $null }
    try {
        $winget.installed = (Test-WinUtilPackageManager -winget 6>$null) -eq "installed"
    } catch {
        $message = "Failed to check WinGet availability: $($_.Exception.Message)"
        Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message $message
        [void]$reportWarnings.Add($message)
    }

    if ($winget.installed) {
        try {
            $global:LASTEXITCODE = 0
            $versionOutput = @(winget -v 2>&1)
            if ($LASTEXITCODE -ne 0) {
                throw "WinGet version probe exited with code $LASTEXITCODE."
            }
            $winget.version = ($versionOutput | Select-Object -First 1).ToString().Trim()
        } catch {
            $message = "Failed to read WinGet version: $($_.Exception.Message)"
            Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message $message
            [void]$reportWarnings.Add($message)
        }
    }

    # Null means the registry state could not be read. Do not turn an access/provider failure into
    # a misleading "no reboot required" result.
    $system = [ordered]@{ pendingRebootRequired = $null }
    try {
        $rebootPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
        )

        # A present-but-empty PendingFileRenameOperations value still returns a non-null object, so
        # check the actual entries rather than just whether the property exists.
        $pendingFileRenameOperations = @(
            (Get-ItemProperty -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" `
                -ErrorAction Stop).PendingFileRenameOperations |
                Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
        )
        $system.pendingRebootRequired = ($rebootPaths | Where-Object {
            Test-Path -LiteralPath $_ -ErrorAction Stop
        }).Count -gt 0 -or
            $pendingFileRenameOperations.Count -gt 0
    } catch {
        $message = "Failed to check pending-reboot registry state: $($_.Exception.Message)"
        Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message $message
        [void]$reportWarnings.Add($message)
    }

    $tweaksState = Get-WinUtilTweaksStateReport
    if ($tweaksState.collectionStatus -ne "collected") {
        $message = "Failed to collect the complete tweak state for the environment report."
        Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message $message
        [void]$reportWarnings.Add($message)
    }

    foreach ($message in $reportWarnings) {
        Write-Warning $message
    }

    return [pscustomobject][ordered]@{
        schemaVersion    = "1.0"
        generatedAtUtc   = [DateTime]::UtcNow.ToString("o")
        windows          = [pscustomobject]$windows
        hardware         = [pscustomobject]$hardware
        powershell       = [pscustomobject]$powershell
        packageManagers  = [pscustomobject][ordered]@{
            winget     = [pscustomobject]$winget
            chocolatey = [pscustomobject]$chocolatey
        }
        system           = [pscustomobject]$system
        tweaksState      = $tweaksState
    }
}
