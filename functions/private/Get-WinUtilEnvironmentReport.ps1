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
    }

    try {
        $processors = @(Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop)
        if ($processors.Count -gt 0) {
            $hardware.cpuModel = $processors[0].Name
            $hardware.logicalProcessorCount = [int](($processors | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum)
        }
    } catch {
    }

    $developerTools = [ordered]@{}
    $toolDefinitions = [ordered]@{
        git = @("git", "--version")
        java = @("java", "-version")
        nodejs = @("node", "--version")
        python = @("python", "--version")
        docker = @("docker", "--version")
    }

    foreach ($toolName in $toolDefinitions.Keys) {
        $toolReport = [ordered]@{
            installed = $false
            version   = $null
        }

        try {
            $command = Get-Command -Name $toolDefinitions[$toolName][0] -CommandType Application -ErrorAction Stop |
                Select-Object -First 1
            if ($null -ne $command) {
                $toolReport.installed = $true
                $output = @(& $command.Source $toolDefinitions[$toolName][1] 2>&1 | ForEach-Object { $_.ToString().Trim() }) -join "`n"
                $versionMatch = [regex]::Match($output, '\d+(?:\.\d+)+(?:[-+._A-Za-z0-9]+)?')
                if ($versionMatch.Success) {
                    $toolReport.version = $versionMatch.Value
                }
            }
        } catch {
        }

        $developerTools[$toolName] = [pscustomobject]$toolReport
    }

    $windowsFeatures = [ordered]@{}
    $featureDefinitions = [ordered]@{
        hyperV = "Microsoft-Hyper-V-All"
        wsl = "Microsoft-Windows-Subsystem-Linux"
        windowsSandbox = "Containers-DisposableClientVM"
    }

    foreach ($featureName in $featureDefinitions.Keys) {
        $featureReport = [ordered]@{ enabled = $false }
        try {
            $feature = Get-WindowsOptionalFeature -Online -FeatureName $featureDefinitions[$featureName] -ErrorAction Stop
            $featureReport.enabled = $feature.State -eq "Enabled"
        } catch {
        }

        $windowsFeatures[$featureName] = [pscustomobject]$featureReport
    }

    return [pscustomobject][ordered]@{
        schemaVersion   = "1.0"
        generatedAtUtc  = [DateTime]::UtcNow.ToString("o")
        windows         = [pscustomobject]$windows
        hardware        = [pscustomobject]$hardware
        powershell      = [pscustomobject][ordered]@{
            edition = $PSVersionTable.PSEdition
            version = $PSVersionTable.PSVersion.ToString()
        }
        developerTools  = [pscustomobject]$developerTools
        windowsFeatures = [pscustomobject]$windowsFeatures
    }
}
