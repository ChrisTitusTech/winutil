function Invoke-WPFtweaksbutton{
  $Tweaks = Get-WinUtilCheckBoxes -Group "WPFTweaks"
  Invoke-TweaksAction $Tweaks
}
function Invoke-TweaksAction {
  # TODO: add support for confrim and whatif
  Param(
    [Parameter(Mandatory=$true)]
    [string[]]$Tweaks,
    [Parameter(Mandatory=$false)]
    [switch]$undo
  )
  if($sync.ProcessRunning){
    $msg = "Install process is currently running."
    Show-Message -PromptType "OK" -Title "Winutil" -Text $msg -Severity "Warning"
    return
  }

  Set-WinUtilDNS -DNSProvider $sync["WPFchangedns"].text

  if ($tweaks.count -eq 0 -and  $sync["WPFchangedns"].text -eq "Default"){
    $msg = "Please check the tweaks you wish to perform."
    Show-Message -PromptType "OK" -Title "Winutil" -Text $msg -Severity "Warning"
    return
  }

  Set-WinUtilRestorePoint

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

    $ButtonType = "OK"
    $MessageboxTitle = "Tweaks are Finished "
    $Messageboxbody = ("Done")
    $MessageIcon = "Information"

    Show-Message -PromptType $ButtonType -Title $MessageboxTitle -Text $Messageboxbody -Severity $MessageIcon
  }
}