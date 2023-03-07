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

  Set-WinUtilDNS -DNSProvider $WPFchangedns.text

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