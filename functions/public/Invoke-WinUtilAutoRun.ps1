function Invoke-WinUtilAutoRun {
    <#

    .SYNOPSIS
        Runs Install, Tweaks, and Features with optional UI invocation.
    #>

    function BusyWait {
        Start-Sleep -Seconds 5
        while ($sync.ProcessRunning) {
                Start-Sleep -Seconds 5
            }
    }

    function Get-DnsProviderForAutoRun {
        if ($sync.ContainsKey("WPFchangedns") -and $null -ne $sync["WPFchangedns"]) {
            $provider = [string]$sync["WPFchangedns"].Text
            if (-not [string]::IsNullOrWhiteSpace($provider)) {
                return $provider
            }
        }

        return "Default"
    }

    BusyWait

    $dnsProvider = Get-DnsProviderForAutoRun

    if ($sync.selectedTweaks.Count -gt 0 -or $dnsProvider -ne "Default") {
        Write-Host "Applying tweaks..."
        Invoke-WPFtweaksbutton
        BusyWait
    }

    if ($sync.selectedToggles.Count -gt 0) {
        Write-Host "Applying toggles..."
        $handle = Invoke-WPFRunspace -ScriptBlock {
            $Toggles = $sync.selectedToggles
            Write-Debug "Inside Number of toggles to process: $($Toggles.Count)"

            $sync.ProcessRunning = $true

            for ($i = 0; $i -lt $Toggles.Count; $i++) {
                Invoke-WinUtilTweaks $Toggles[$i]
            }

            $sync.ProcessRunning = $false
            Write-Host "================================="
            Write-Host "--     Toggles are Finished    ---"
            Write-Host "================================="
        }
        BusyWait
    }

    if ($sync.selectedFeatures.Count -gt 0) {
        Write-Host "Applying features..."
        Invoke-WPFFeatureInstall
        BusyWait
    }

    if ($sync.selectedApps.Count -gt 0) {
        Write-Host "Installing applications..."
        Invoke-WPFInstall
        BusyWait
    }

    Write-Host "Done."
}
