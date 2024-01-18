function Invoke-WPFtweaksbutton {
  <#

    .SYNOPSIS
        Invokes the functions associated with each group of checkboxes

  #>

  if($sync.ProcessRunning){
    $msg = "[Invoke-WPFtweaksbutton] Install process is currently running."
    [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    return
  }

  $Tweaks = (Get-WinUtilCheckBoxes)["WPFTweaks"]
  
  Set-WinUtilDNS -DNSProvider $sync["WPFchangedns"].text

  if ($tweaks.count -eq 0 -and  $sync["WPFchangedns"].text -eq "Default"){
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


    # Assuming your App.xaml contains a ResourceDictionary with the defined theme
$themeResource = [System.Windows.Markup.XamlLoader]::Load((New-Object System.IO.StreamReader("App.xaml")).BaseStream)

# Find the existing ResourceDictionary and remove it
[Windows.Markup.XamlLoader]::Load("App.xaml").Application.Resources.MergedDictionaries.Clear()

# Add the new ResourceDictionary (reloading the theme)
[Windows.Markup.XamlLoader]::Load("App.xaml").Application.Resources.MergedDictionaries.Add($themeResource)


    $form.FindName("YourButtonName").InvalidateProperty([Windows.Controls.Control]::BackgroundProperty)
    $sync["Form"].Refresh()
  }
}