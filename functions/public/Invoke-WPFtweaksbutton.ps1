function Invoke-WPFtweaksbutton {
    $Tweaks = Get-WinUtilCheckBoxes -Group "WPFTweaks"

    Set-WinUtilDNS -DNSProvider $WPFchangedns.text
  
    Invoke-WPFRunspace -ArgumentList $Tweaks -ScriptBlock {
      param($Tweaks)
  
      Foreach ($tweak in $tweaks){
          Invoke-WinUtilTweaks $tweak
      }
  
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