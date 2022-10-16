 # Source: https://github.com/rgl/windows-vagrant/blob/master/disable-windows-updates.ps1 reversed! 
 Set-StrictMode -Version Latest
 $ProgressPreference = 'SilentlyContinue'
 $ErrorActionPreference = 'Stop'
 trap {
     Write-Host
     Write-Host "ERROR: $_"
     Write-Host (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$', 'ERROR: $1')
     Write-Host (($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$', 'ERROR EXCEPTION: $1')
     Write-Host
     Write-Host 'Sleeping for 60m to give you time to look around the virtual machine before self-destruction...'
     Start-Sleep -Seconds (60 * 60)
     Exit 1
 }

 # disable automatic updates.
 # XXX this does not seem to work anymore.
 # see How to configure automatic updates by using Group Policy or registry settings
 #     at https://support.microsoft.com/en-us/help/328010
 function New-Directory($path) {
     $p, $components = $path -split '[\\/]'
     $components | ForEach-Object {
         $p = "$p\$_"
         If (!(Test-Path $p)) {
             New-Item -ItemType Directory $p | Out-Null
         }
     }
     $null
 }
 $auPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
 New-Directory $auPath 
 # set NoAutoUpdate.
 # 0: Automatic Updates is enabled (default).
 # 1: Automatic Updates is disabled.
 New-ItemProperty `
     -Path $auPath `
     -Name NoAutoUpdate `
     -Value 0 `
     -PropertyType DWORD `
     -Force `
 | Out-Null
 # set AUOptions.
 # 1: Keep my computer up to date has been disabled in Automatic Updates.
 # 2: Notify of download and installation.
 # 3: Automatically download and notify of installation.
 # 4: Automatically download and scheduled installation.
 New-ItemProperty `
     -Path $auPath `
     -Name AUOptions `
     -Value 3 `
     -PropertyType DWORD `
     -Force `
 | Out-Null

 # disable Windows Update Delivery Optimization.
 # NB this applies to Windows 10.
 # 0: Disabled
 # 1: PCs on my local network
 # 3: PCs on my local network, and PCs on the Internet
 $deliveryOptimizationPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config'
 If (Test-Path $deliveryOptimizationPath) {
     New-ItemProperty `
         -Path $deliveryOptimizationPath `
         -Name DODownloadMode `
         -Value 0 `
         -PropertyType DWORD `
         -Force `
     | Out-Null
 }
 # Service tweaks for Windows Update

 $services = @(
     "BITS"
     "wuauserv"
 )

 foreach ($service in $services) {
     # -ErrorAction SilentlyContinue is so it doesn't write an error to stdout if a service doesn't exist

     Write-Host "Setting $service StartupType to Automatic"
     Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Automatic
 }
 Write-Host "Enabling driver offering through Windows Update..."
 Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -ErrorAction SilentlyContinue
 Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate" -ErrorAction SilentlyContinue
 Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate" -ErrorAction SilentlyContinue
 Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled" -ErrorAction SilentlyContinue
 Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -ErrorAction SilentlyContinue
 Write-Host "Enabling Windows Update automatic restart..."
 Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -ErrorAction SilentlyContinue
 Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -ErrorAction SilentlyContinue
 Write-Host "Enabled driver offering through Windows Update"
 Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "BranchReadinessLevel" -ErrorAction SilentlyContinue
 Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferFeatureUpdatesPeriodInDays" -ErrorAction SilentlyContinue
 Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferQualityUpdatesPeriodInDays " -ErrorAction SilentlyContinue