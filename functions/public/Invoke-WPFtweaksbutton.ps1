function Invoke-WPFtweaksbutton {
  <#

    .SYNOPSIS
        Invokes the functions associated with each group of checkboxes

  #>

  if ($sync.ProcessRunning) {
    $msg = "[Invoke-WPFtweaksbutton] Install process is currently running."
    [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    return
  }

  Write-Debug "Getting Toggles"
  $toggles = (Get-WinUtilCheckBoxes)["WPFToggle"]
  
  Write-Debug "Got some toggles $($toggles.count)"
  if ($toggles.count -ne 0) {
    Invoke-WPFRunspace -ArgumentList $toggles -DebugPreference $DebugPreference -ScriptBlock {
      param($toggles, $DebugPreference)
      Write-Debug "Inside Number of toggles to process: $($toggles.Count)"
 
      $sync.ProcessRunning = $true
  
      $cnt = 0
      # Execute other selected tweaks
      foreach ($tog in $toggles) {
        Write-Debug "This is a toggle to run $tog count: $cnt"

        $toga = $tog -split ":"

        Write-Debug "Toggles Array: $($toga[0]) Value: $($toga[1])"
        if ($toga[1] -ieq "true") {
          Write-Debug "Setting $toga[0]"
          Invoke-WinUtilTweaks $toga[0]
          pause
        }
        else {
          Write-Debug "Unsetting $toga[0]"
          Invoke-WinUtilTweaks $toga[0] -undo $true
          pause
        }
        $cnt += 1
      }
  
      $sync.ProcessRunning = $false
    }
  }
  
  Set-WinUtilDNS -DNSProvider $sync["WPFchangedns"].text

  $Tweaks = (Get-WinUtilCheckBoxes)["WPFTweaks"]
  if ($Tweaks.count -eq 0 -and  $sync["WPFchangedns"].text -eq "Default"){
    $msg = "Please check the tweaks you wish to perform."
    [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    return
  }

  Write-Debug "Number of tweaks to process: $($Tweaks.Count)"

  Invoke-WPFRunspace -ArgumentList $Tweaks -DebugPreference $DebugPreference -ScriptBlock {
    param($Tweaks, $DebugPreference)
    Write-Debug "Inside Number of tweaks to process: $($Tweaks.Count)"

    $sync.ProcessRunning = $true

    $cnt = 0
    # Execute other selected tweaks
    foreach ($tweak in $Tweaks) {
      Write-Debug "This is a tweak to run $tweak count: $cnt"
      Invoke-WinUtilTweaks $tweak
      $cnt += 1
    }

    $sync.ProcessRunning = $false
    Write-Host "================================="
    Write-Host "--     Tweaks are Finished    ---"
    Write-Host "================================="
  }
}