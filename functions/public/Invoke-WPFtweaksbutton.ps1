function Invoke-WPFtweaksbutton {
  <#
  
      .DESCRIPTION
      PlaceHolder
  
  #>

  if($sync.ProcessRunning){
    $msg = "Install process is currently running."
    [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    return
  }

  $Tweaks = Get-WinUtilCheckBoxes -Group "WPFTweaks"

  Set-WinUtilDNS -DNSProvider $sync["WPFchangedns"].text

  if ($tweaks.count -eq 0 -and  $sync["WPFchangedns"].text -eq "Default"){
    $msg = "Please check the tweaks you wish to perform."
    [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    return
  }

  Invoke-WPFRunspace -ArgumentList $Tweaks -ScriptBlock {
    param($Tweaks)

    $sync.ProcessRunning = $true

    Foreach ($tweak in $tweaks){
        Invoke-WinUtilTweaks $tweak
    }

    $sync.ProcessRunning = $false
    Write-Host "================================="
    Write-Host "--     Tweaks are Finished    ---"
    Write-Host "================================="

    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageboxTitle = "Tweaks are Finished "
    $Messageboxbody = ("Done")
    $MessageIcon = [System.Windows.MessageBoxImage]::Information

    [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)
  }
}