function Invoke-WPFundoall {
    <#

    .SYNOPSIS
        Undoes every selected tweak

    #>

    if ($sync.ProcessRunning) {
        $msg = "[Invoke-WPFundoall] Install process is currently running."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $Tweaks = (Get-WinUtilCheckBoxes)["WPFTweaks"]

    if ($tweaks.count -eq 0) {
        $msg = "Please check the tweaks you wish to undo."
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Invoke-WPFRunspace -ArgumentList $Tweaks, $DebugPreference -ScriptBlock {
        param($Tweaks, $DebugPreference)

        $sync.ProcessRunning = $true

        foreach ($tweak in $tweaks) {
            Invoke-WinUtilTweaks $tweak -undo $true
        }

        $sync.ProcessRunning = $false
        Write-Host "=================================="
        Write-Host "---  Undo Tweaks are Finished  ---"
        Write-Host "=================================="
    }
}