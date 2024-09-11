function Invoke-WPFtweaksbutton {
  <#

    .SYNOPSIS
        Invokes the functions associated with each group of checkboxes

  #>

  if($sync.ProcessRunning) {
    $msg = "[Invoke-WPFtweaksbutton] Install process is currently running."
    [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    return
  }

  $Tweaks = (Get-WinUtilCheckBoxes)["WPFTweaks"]
  $DNSChange = $sync["WPFchangedns"].text -ne "Default"

  if ($DNSChange) {
    Set-WinUtilDNS -DNSProvider $sync["WPFchangedns"].text
  }

  if ($tweaks.count -eq 0 -and -not $DNSChange) {
    $msg = "Please check the tweaks you wish to perform or select a DNS provider."
    [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    return
  }

  Write-Debug "Number of tweaks to process: $($Tweaks.Count)"

  try {
    $handle = Invoke-WPFRunspace -ArgumentList $Tweaks, $DNSChange -DebugPreference $DebugPreference -ScriptBlock {
      param($Tweaks, $DNSChange, $DebugPreference)
      Write-Debug "Inside Number of tweaks to process: $($Tweaks.Count)"

      $sync.ProcessRunning = $true

      if ($Tweaks.count -eq 0 -and $DNSChange) {
          $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo" })
      } elseif ($Tweaks.count -eq 1) {
          $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo" })
      } else {
          $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Normal" -value 0.01 -overlay "logo" })
      }

      # Execute selected tweaks
      for ($i = 0; $i -lt $Tweaks.Count; $i++) {
        $currentTweak = $Tweaks[$i]
        Set-WinUtilProgressBar -Label "Applying $currentTweak" -Percent ($i / $Tweaks.Count * 100)

        # Apply the current tweak
        Invoke-WinUtilTweaks $currentTweak

        # Update taskbar progress
        $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -value (($i + 1) / $Tweaks.Count) })
      }

      Set-WinUtilProgressBar -Label "Tweaks finished" -Percent 100
      $sync.ProcessRunning = $false
      $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" })
      Write-Host "================================="
      Write-Host "--     Tweaks are Finished    ---"
      Write-Host "================================="
    }

    # Optionally, you can add code here to update the UI or perform other tasks while the runspace is executing
    # For example, you might want to disable certain UI elements until the runspace completes

    # If you need to wait for completion before proceeding, you can use:
    # $handle.AsyncWaitHandle.WaitOne()
    # But be cautious about blocking the UI thread

    Write-Host "Tweaks execution started in background."
  }
  catch {
    Write-Error "Failed to start tweaks execution: $_"
    [System.Windows.MessageBox]::Show("An error occurred while starting tweaks execution. Please check the logs for more information.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
  }
}
