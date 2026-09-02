function Get-WinUtilEnvironmentReport {
    <#
    .SYNOPSIS
        Collects the allowlisted data used by the WinUtil environment report.
    #>

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
        Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message "Failed to collect Windows/memory info from Win32_OperatingSystem: $($_.Exception.Message)"
    }

    try {
        $processors = @(Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop)
        if ($processors.Count -gt 0) {
            $hardware.cpuModel = $processors[0].Name
            $hardware.logicalProcessorCount = [int](($processors | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum)
        }
    } catch {
        Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message "Failed to collect CPU info from Win32_Processor: $($_.Exception.Message)"
    }

    $powershell = [ordered]@{
        edition         = $PSVersionTable.PSEdition
        version         = $PSVersionTable.PSVersion.ToString()
        executionPolicy = $null
    }

    try {
        $powershell.executionPolicy = (Get-ExecutionPolicy).ToString()
    } catch {
        Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message "Failed to read PowerShell execution policy: $($_.Exception.Message)"
    }

    # Re-use built-in functionality
    $chocolatey = [ordered]@{ installed = $false; version = $null }
    try {
        $chocolatey.installed = (Test-WinUtilPackageManager -choco 6>$null) -eq "installed"
    } catch {
        Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message "Failed to check Chocolatey availability: $($_.Exception.Message)"
    }

    if ($chocolatey.installed) {
        try {
            $chocolatey.version = (choco -v 2>&1 | Select-Object -First 1).ToString().Trim()
        } catch {
            Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message "Failed to read Chocolatey version: $($_.Exception.Message)"
        }
    }

    $winget = [ordered]@{ installed = $false; version = $null }
    try {
        $winget.installed = (Test-WinUtilPackageManager -winget 6>$null) -eq "installed"
    } catch {
        Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message "Failed to check WinGet availability: $($_.Exception.Message)"
    }

    if ($winget.installed) {
        try {
            $winget.version = (winget -v 2>&1 | Select-Object -First 1).ToString().Trim()
        } catch {
            Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message "Failed to read WinGet version: $($_.Exception.Message)"
        }
    }

    $system = [ordered]@{ pendingRebootRequired = $false }
    try {
        $rebootPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
        )

        # A present-but-empty PendingFileRenameOperations value still returns a non-null object, so
        # check the actual entries rather than just whether the property exists.
        $pendingFileRenameOperations = @(
            (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" `
                -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue).PendingFileRenameOperations |
                Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
        )
        $system.pendingRebootRequired = ($rebootPaths | Where-Object { Test-Path $_ }).Count -gt 0 -or
            $pendingFileRenameOperations.Count -gt 0
    } catch {
        Write-WinUtilLog -Component "EnvironmentReport" -Level "WARN" -Message "Failed to check pending-reboot registry state: $($_.Exception.Message)"
    }

    $tweaksState = Get-WinUtilTweaksStateReport

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
