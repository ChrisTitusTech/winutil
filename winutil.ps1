#for CI/CD
$BranchToUse = 'test-12-2022'

<#
.NOTES
   Author      : Chris Titus @christitustech
   GitHub      : https://github.com/ChrisTitusTech
    Version 0.0.1
#>

#region exception classes

    class WingetFailedInstall : Exception {
        [string] $additionalData

        WingetFailedInstall($Message) : base($Message) {}
    }
    
    class ChocoFailedInstall : Exception {
        [string] $additionalData

        ChocoFailedInstall($Message) : base($Message) {}
    }

#endregion exception classes

Start-Transcript $ENV:TEMP\Winutil.log -Append

# variable to sync between runspaces
$sync = [Hashtable]::Synchronized(@{})
$sync.BranchToUse = $BranchToUse
$sync.PSScriptRoot = $PSScriptRoot
if (!$sync.PSScriptRoot){$sync.PSScriptRoot = (Get-Location).Path}

$inputXML = Get-Content "$($sync.PSScriptRoot)\MainWindow.xaml" #uncomment for development
#$inputXML = (new-object Net.WebClient).DownloadString("https://raw.githubusercontent.com/ChrisTitusTech/winutil/$BranchToUse/MainWindow.xaml") #uncomment for Production

$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try { $Form = [Windows.Markup.XamlReader]::Load( $reader ) }
catch [System.Management.Automation.MethodInvocationException] {
    Write-Warning "We ran into a problem with the XAML code.  Check the syntax for this control..."
    Write-Host $error[0].Exception.Message -ForegroundColor Red
    If ($error[0].Exception.Message -like "*button*") {
        write-warning "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n"
    }
}
catch {
    # If it broke some other way <img draggable="false" role="img" class="emoji" alt="😀" src="https://s0.wp.com/wp-content/mu-plugins/wpcom-smileys/twemoji/2/svg/1f600.svg">
    Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
}

#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================

$xaml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) }

#===========================================================================
# Functions
#===========================================================================

Function Get-FormVariables {
    #If ($global:ReadmeDisplay -ne $true) { Write-Host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow; $global:ReadmeDisplay = $true }


    Write-Host ""
    Write-Host "    CCCCCCCCCCCCCTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT   "
    Write-Host " CCC::::::::::::CT:::::::::::::::::::::TT:::::::::::::::::::::T   "
    Write-Host "CC:::::::::::::::CT:::::::::::::::::::::TT:::::::::::::::::::::T  "
    Write-Host "C:::::CCCCCCCC::::CT:::::TT:::::::TT:::::TT:::::TT:::::::TT:::::T "
    Write-Host "C:::::C       CCCCCCTTTTTT  T:::::T  TTTTTTTTTTTT  T:::::T  TTTTTT"
    Write-Host "C:::::C                     T:::::T                T:::::T        "
    Write-Host "C:::::C                     T:::::T                T:::::T        "
    Write-Host "C:::::C                     T:::::T                T:::::T        "
    Write-Host "C:::::C                     T:::::T                T:::::T        "
    Write-Host "C:::::C                     T:::::T                T:::::T        "
    Write-Host "C:::::C                     T:::::T                T:::::T        "
    Write-Host "C:::::C       CCCCCC        T:::::T                T:::::T        "
    Write-Host "C:::::CCCCCCCC::::C      TT:::::::TT            TT:::::::TT       "
    Write-Host "CC:::::::::::::::C       T:::::::::T            T:::::::::T       "
    Write-Host "CCC::::::::::::C         T:::::::::T            T:::::::::T       "
    Write-Host "  CCCCCCCCCCCCC          TTTTTTTTTTT            TTTTTTTTTTT       "
    Write-Host ""
    Write-Host "====Chris Titus Tech====="
    Write-Host "=====Windows Toolbox====="


    #====DEBUG GUI Elements====

    #Write-Host "Found the following interactable elements from our form" -ForegroundColor Cyan
    #get-variable WPF*
}

Function Get-CheckBoxes {

    <#

        .DESCRIPTION
        Function is meant to find all checkboxes that are checked on the specefic tab and input them into a script.

        Outputed data will be the names of the checkboxes that were checked

        .EXAMPLE

        Get-CheckBoxes "WPFInstall"

    #>

    Param($Group)

    $CheckBoxes = get-variable | Where-Object {$psitem.name -like "$Group*" -and $psitem.value.GetType().name -eq "CheckBox"}
    $Output = New-Object System.Collections.Generic.List[System.Object]

    if($Group -eq "WPFInstall"){
        Foreach ($CheckBox in $CheckBoxes){
            if($CheckBox.value.ischecked -eq $true){
                $sync.configs.applications.$($CheckBox.name).winget -split ";" | ForEach-Object {
                    $Output.Add($psitem)
                }

                $CheckBox.value.ischecked = $false
            }
        }
    }

    Write-Output $($Output | Select-Object -Unique)
}

function Set-Presets {
    <#

        .DESCRIPTION
        Meant to make settings presets easier in the tweaks tab. Will pull the data from config/preset.json

    #>

    param($preset)
    $CheckBoxesToCheck = $sync.configs.preset.$preset

    #Uncheck all
    get-variable | Where-Object {$_.name -like "*tweaks*"} | ForEach-Object {
        if ($psitem.value.gettype().name -eq "CheckBox"){
            $CheckBox = Get-Variable $psitem.Name
            if ($CheckBoxesToCheck -contains $CheckBox.name){
                $checkbox.value.ischecked = $true
            }
            else{$checkbox.value.ischecked = $false}
        }
    }

}

function Switch-Tab {

    <#
    
        .DESCRIPTION
        Sole purpose of this fuction reduce duplicated code for switching between tabs. 
    
    #>

    Param ($ClickedTab)
    $Tabs = Get-Variable WPFTab?BT
    $TabNav = Get-Variable WPFTabNav
    $x = [int]($ClickedTab -replace "WPFTab","" -replace "BT","") - 1

    0..($Tabs.Count -1 ) | ForEach-Object {
        
        if ($x -eq $psitem){
            $TabNav.value.Items[$psitem].IsSelected = $true
        }
        else{
            $TabNav.value.Items[$psitem].IsSelected = $false
        }
    }
}

function Get-InstallerProcess {
    <#
    
        .DESCRIPTION
        Meant to check for running processes and will return a boolean response
    
    #>

    param($Process)

    if ($Null -eq $Process){
        return $false
    }
    if (Get-Process -Id $Process.Id -ErrorAction SilentlyContinue){
        return $true
    }
    return $false
}

Function Install-ProgramWinget {

    <#
    
        .DESCRIPTION
        This will install programs via Winget using a new powershell.exe instance to prevent the GUI from locking up.

        Note the triple quotes are required any time you need a " in a normal script block.
    
    #>

    param($ProgramsToInstall)

    [ScriptBlock]$wingetinstall = {
        param($ProgramsToInstall)

        $host.ui.RawUI.WindowTitle = """Winget Install"""

        $x = 0
        $count = $($ProgramsToInstall -split """,""").Count

        Write-Progress -Activity """Installing Applications""" -Status """Starting""" -PercentComplete 0
    
        Write-Host """`n`n`n`n`n`n"""
        
        Start-Transcript $ENV:TEMP\winget.log -Append
    
        Foreach ($Program in $($ProgramsToInstall -split """,""")){
    
            Write-Progress -Activity """Installing Applications""" -Status """Installing $Program $($x + 1) of $count""" -PercentComplete $($x/$count*100)
            Start-Process -FilePath winget -ArgumentList """install -e --accept-source-agreements --accept-package-agreements --silent $Program""" -NoNewWindow -Wait;
            $X++
        }

        Write-Progress -Activity """Installing Applications""" -Status """Finished""" -Completed
        Write-Host """`n`nAll Programs have been installed"""
        Pause
    }

    $global:WinGetInstall = Start-Process -Verb runas powershell -ArgumentList "-command invoke-command -scriptblock {$wingetinstall} -argumentlist '$($ProgramsToInstall -join ",")'" -PassThru

}

Function Update-ProgramWinget {

    <#
    
        .DESCRIPTION
        This will update programs via Winget using a new powershell.exe instance to prevent the GUI from locking up.
    
    #>

    [ScriptBlock]$wingetinstall = {

        $host.ui.RawUI.WindowTitle = """Winget Install"""

        Start-Transcript $ENV:TEMP\winget-update.log -Append
        winget upgrade --all

        Pause
    }

    $global:WinGetInstall = Start-Process -Verb runas powershell -ArgumentList "-command invoke-command -scriptblock {$wingetinstall} -argumentlist '$($ProgramsToInstall -join ",")'" -PassThru

}

function Test-PackageManager {
    Param(
        [System.Management.Automation.SwitchParameter]$winget,
        [System.Management.Automation.SwitchParameter]$choco
    )

    if($winget){
        if (Test-Path ~\AppData\Local\Microsoft\WindowsApps\winget.exe) {
            return $true
        }
    }

    if($choco){
        if ((Get-Command -Name choco -ErrorAction Ignore) -and ($chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion)){
            return $true
        }
    }

    return $false
}

function Install-Winget {

    <#
    
        .DESCRIPTION
        Function is meant to ensure winget is installed 
    
    #>

    Try{
        Write-Host "Checking if Winget is Installed..."
        if (Test-PackageManager -winget) {
            #Checks if winget executable exists and if the Windows Version is 1809 or higher
            Write-Host "Winget Already Installed"
            return
        }

        #Gets the computer's information
        if ($null -eq $sync.ComputerInfo){
            $ComputerInfo = Get-ComputerInfo -ErrorAction Stop
        }
        Else {
            $ComputerInfo = $sync.ComputerInfo
        }

        if (($ComputerInfo.WindowsVersion) -lt "1809") {
            #Checks if Windows Version is too old for winget
            Write-Host "Winget is not supported on this version of Windows (Pre-1809)"
            return
        }

        #Gets the Windows Edition
        $OSName = if ($ComputerInfo.OSName) {
            $ComputerInfo.OSName
        }else {
            $ComputerInfo.WindowsProductName
        }

        if (((($OSName.IndexOf("LTSC")) -ne -1) -or ($OSName.IndexOf("Server") -ne -1)) -and (($ComputerInfo.WindowsVersion) -ge "1809")) {

            Write-Host "Running Alternative Installer for LTSC/Server Editions"

            # Switching to winget-install from PSGallery from asheroto
            # Source: https://github.com/asheroto/winget-installer

            Start-Process powershell.exe -Verb RunAs -ArgumentList "-command irm https://raw.githubusercontent.com/ChrisTitusTech/winutil/$BranchToUse/winget.ps1 | iex | Out-Host" -WindowStyle Normal -ErrorAction Stop

            if(!(Test-PackageManager -winget)){
                break
            }
        }

        else {
            #Installing Winget from the Microsoft Store
            Write-Host "Winget not found, installing it now."
            Start-Process "ms-appinstaller:?source=https://aka.ms/getwinget"
            $nid = (Get-Process AppInstaller).Id
            Wait-Process -Id $nid

            if(!(Test-PackageManager -winget)){
                break
            }
        }
        Write-Host "Winget Installed"
    }
    Catch{
        throw [WingetFailedInstall]::new('Failed to install')
    }

    # Check if chocolatey is installed and get its version

}

function Install-Choco {
    try{
        Write-Host "Checking if Chocolatey is Installed..."

        if((Test-PackageManager -choco)){
            Write-Host "Chocolatey Already Installed"
            return
        }
    
        Write-Host "Seems Chocolatey is not installed, installing now?"
        #Let user decide if he wants to install Chocolatey
        $confirmation = Read-Host "Are you Sure You Want To Proceed:(y/n)"
        if ($confirmation -eq 'y') {
            Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) -ErrorAction Stop
            powershell choco feature enable -n allowGlobalConfirmation
        }
    }
    Catch{
        throw [ChocoFailedInstall]::new('Failed to install')
    }

}

function Invoke-Runspace {

    <#
    
        .DESCRIPTION
        Simple function to make it easier to invoke a runspace from inside the script. 

        .EXAMPLE

        $params = @{
            ScriptBlock = $sync.ScriptsInstallPrograms
            ArgumentList = "Installadvancedip,Installbitwarden"
            Verbose = $true
        }

        Invoke-Runspace @params
    
    #>

    [CmdletBinding()]
    Param (
        $ScriptBlock,
        $ArgumentList
    ) 

    $Script = [PowerShell]::Create().AddScript($ScriptBlock).AddArgument($ArgumentList)

    $Script.Runspace = $runspace
    $Script.BeginInvoke()
}

function Invoke-WinTweaks {
    param($CheckBox)
    if($sync.configs.tweaks.$CheckBox.registry){
        $sync.configs.tweaks.$CheckBox.registry | ForEach-Object {
            Set-WinUtilRegistry -Name $psitem.Name -Path $psitem.Path -Type $psitem.Type -Value $psitem.Value 
        }
    }
    if($sync.configs.tweaks.$CheckBox.ScheduledTask){
        $sync.configs.tweaks.$CheckBox.ScheduledTask | ForEach-Object {
            Set-WinUtilScheduledTask -Name $psitem.Name -State $psitem.State
        }
    }
    if($sync.configs.tweaks.$CheckBox.service){
        $sync.configs.tweaks.$CheckBox.service | ForEach-Object {
            Set-WinUtilService -Name $psitem.Name -StartupType $psitem.StartupType
        }
    }
    if($sync.configs.tweaks.$CheckBox.InvokeScript){
        $sync.configs.tweaks.$CheckBox.InvokeScript | ForEach-Object {
            $Scriptblock = [scriptblock]::Create($psitem)
            Invoke-WinUtilScript -ScriptBlock $scriptblock -Name $CheckBox
        }
    }
}

function Set-WinUtilRegistry {
    param (
        $Name,
        $Path,
        $Type,
        $Value
    )

    Try{      
        if(!(Test-Path 'HKU:\')){New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS}

        If (!(Test-Path $Path)) {
            Write-Host "$Path was not found, Creating..."
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
        }

        Write-Host "Set $Path\$Name to $Value"
        Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value -Force -ErrorAction Stop | Out-Null
    }
    Catch [System.Security.SecurityException] {
        Write-Warning "Unable to set $Path\$Name to $Value due to a Security Exception"
    }
    Catch [System.Management.Automation.ItemNotFoundException] {
        Write-Warning $psitem.Exception.ErrorRecord
    }
    Catch{
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}

Function Set-WinUtilService {
    param (
        $Name,
        $StartupType
    )
    Try{
        Write-Host "Setting Services $Name to $StartupType"
        Set-Service -Name $Name -StartupType $StartupType -ErrorAction Stop

        if($StartupType -eq "Disabled"){
            Write-Host "Stopping $Name"
            Stop-Service -Name $Name -Force -ErrorAction Stop
        }
        if($StartupType -eq "Enabled"){
            Write-Host "Starting $Name"
            Start-Service -Name $Name -Force -ErrorAction Stop
        }
    }
    Catch [System.Exception]{
        if($psitem.Exception.Message -like "*Cannot find any service with service name*" -or 
           $psitem.Exception.Message -like "*was not found on computer*"){
            Write-Warning "Service $name was not Found"
        }
        Else{
            Write-Warning "Unable to set $Name due to unhandled exception"
            Write-Warning $psitem.Exception.Message
        }
    }
    Catch{
        Write-Warning "Unable to set $Name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}

function Invoke-WinUtilScript {
    param (
        $Name,
        [scriptblock]$scriptblock
    )

    Try{
        Start-Process powershell.exe -Verb runas -ArgumentList "-Command  $scriptblock" -Wait -ErrorAction Stop
    }
    Catch{
        Write-Warning "Unable to run script for $name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace 
    }
}

function Set-WinUtilScheduledTask {
    param (
        $Name,
        $State
    )

    Try{
        if($State -eq "Disabled"){
            Write-Host "Disabling Scheduled Task $Name"
            Disable-ScheduledTask -TaskName $Name -ErrorAction Stop
        }
        if($State -eq "Enabled"){
            Write-Host "Enabling Scheduled Task $Name"
            Enable-ScheduledTask -TaskName $Name -ErrorAction Stop
        }
    }
    Catch [System.Exception]{
        if($psitem.Exception.Message -like "*The system cannot find the file specified*"){
            Write-Warning "Scheduled Task $name was not Found"
        }
        Else{
            Write-Warning "Unable to set $Name due to unhandled exception"
            Write-Warning $psitem.Exception.Message
        }
    }
    Catch{
        Write-Warning "Unable to run script for $name due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace 
    }
}

function Set-WinUtilDNS {
    param($DNSProvider)
    if($DNSProvider -eq "Default"){return}
    Try{
        $Adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
        Write-Host "Ensuring DNS is set to $DNSProvider on the following interfaces"
        Write-Host $($Adapters | Out-String)

        Foreach ($Adapter in $Adapters){
            if($DNSProvider -eq "DHCP"){
                Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ResetServerAddresses
            }
            Else{
                Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses ("$($sync.configs.dns.$DNSProvider.Primary)", "$($sync.configs.dns.$DNSProvider.Secondary)")
            }
        }
    }
    Catch{
        Write-Warning "Unable to set DNS Provider due to an unhandled exception"
        Write-Warning $psitem.Exception.StackTrace 
    }
}

#===========================================================================
# Global Variables
#===========================================================================

$AppTitle = "Chris Titus Tech's Windows Utility"

#===========================================================================
# Navigation Controls
#===========================================================================

$WPFTab1BT.Add_Click({
        Switch-Tab "WPFTab1BT"
    })
$WPFTab2BT.Add_Click({
        Switch-Tab "WPFTab2BT"
    })
$WPFTab3BT.Add_Click({
        Switch-Tab "WPFTab3BT"
    })
$WPFTab4BT.Add_Click({
        Switch-Tab "WPFTab4BT"
    })

#===========================================================================
# Tab 1 - Install
#===========================================================================

$WPFinstall.Add_Click({

    $WingetInstall = Get-CheckBoxes -Group "WPFInstall"

    if ($wingetinstall.Count -eq 0) {
        $WarningMsg = "Please select the program(s) to install"
        [System.Windows.MessageBox]::Show($WarningMsg, $AppTitle, [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    if(Get-InstallerProcess -Process $global:WinGetInstall){
        $msg = "Install process is currently running. Please check for a powershell window labled 'Winget Install'"
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    try{

        # Ensure winget is installed
        Install-Winget

        # Install all winget programs in new window
        Install-ProgramWinget -ProgramsToInstall $WingetInstall  

        Write-Host "==========================================="
        Write-Host "--          Installs started            ---"
        Write-Host "-- You can close this window if desired ---"
        Write-Host "==========================================="
    }
    Catch [WingetFailedInstall]{
        Write-Host "==========================================="
        Write-Host "--      Winget failed to install        ---"
        Write-Host "==========================================="
    }

})

$WPFInstallUpgrade.Add_Click({
    if(!(Test-PackageManager -winget)){
        Write-Host "==========================================="
        Write-Host "--       Winget is not installed        ---"
        Write-Host "==========================================="
        return
    }

    if(Get-InstallerProcess -Process $global:WinGetInstall){
        $msg = "Install process is currently running. Please check for a powershell window labled 'Winget Install'"
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Update-ProgramWinget

    Write-Host "==========================================="
    Write-Host "--           Updates started            ---"
    Write-Host "-- You can close this window if desired ---"
    Write-Host "==========================================="
})

#===========================================================================
# Tab 2 - Tweak Buttons
#===========================================================================
$WPFdesktop.Add_Click({
    Set-Presets "Desktop"
})

$WPFlaptop.Add_Click({
    Set-Presets "laptop"
})

$WPFminimal.Add_Click({
    Set-Presets "minimal"
})



$WPFtweaksbutton.Add_Click({

    Set-WinUtilDNS -DNSProvider $WPFchangedns.text

    If ( $WPFEssTweaksAH.IsChecked -eq $true ) {
        Write-Host "Disabling Activity History..."
        Invoke-WinTweaks "WPFEssTweaksAH"
        $WPFEssTweaksAH.IsChecked = $false
    }

    If ( $WPFEssTweaksDeleteTempFiles.IsChecked -eq $true ) {
        Write-Host "Delete Temp Files"
        Invoke-WinTweaks WPFEssTweaksDeleteTempFiles
        $WPFEssTweaksDeleteTempFiles.IsChecked = $false
        Write-Host "======================================="
        Write-Host "--- Cleaned following folders:"
        Write-Host "--- C:\Windows\Temp"
        Write-Host "--- "$env:TEMP
        Write-Host "======================================="
    }
    If ( $WPFEssTweaksDVR.IsChecked -eq $true ) {

        Write-Host "Disabling GameDVR..."
        Invoke-WinTweaks "WPFEssTweaksDVR"

        $WPFEssTweaksDVR.IsChecked = $false
    }
    If ( $WPFEssTweaksHiber.IsChecked -eq $true  ) {
        Write-Host "Disabling Hibernation..."
        Invoke-WinTweaks WPFEssTweaksHiber
        $WPFEssTweaksHiber.IsChecked = $false
    }
    If ( $WPFEssTweaksHome.IsChecked -eq $true ) {
        Invoke-WinTweaks WPFEssTweaksHome
        $WPFEssTweaksHome.IsChecked = $false
    }
    If ( $WPFEssTweaksLoc.IsChecked -eq $true ) {
        Write-Host "Disabling Location Tracking..."
        Write-Host "Disabling automatic Maps updates..."
        Invoke-WinTweaks WPFEssTweaksLoc
        $WPFEssTweaksLoc.IsChecked = $false
    }
    If ( $WPFMiscTweaksDisableTPMCheck.IsChecked -eq $true ) {
        Write-Host "Disabling TPM Check..."
        Invoke-WinTweaks WPFMiscTweaksDisableTPMCheck
        $WPFMiscTweaksDisableTPMCheck.IsChecked = $false
    }
    If ( $WPFEssTweaksDiskCleanup.IsChecked -eq $true ) {
        Write-Host "Running Disk Cleanup on Drive C:..."
        Invoke-WinTweaks WPFEssTweaksDiskCleanup
        $WPFEssTweaksDiskCleanup.IsChecked = $false
    }
    If ( $WPFMiscTweaksDisableUAC.IsChecked -eq $true) {
        Write-Host "Disabling UAC..."
        Invoke-WinTweaks WPFMiscTweaksDisableUAC
        $WPFMiscTweaksDisableUAC.IsChecked = $false
    }
    If ( $WPFMiscTweaksDisableNotifications.IsChecked -eq $true ) {
        Write-Host "Disabling Notifications and Action Center..."
        Invoke-WinTweaks WPFMiscTweaksDisableNotifications
        $WPFMiscTweaksDisableNotifications.IsChecked = $false
    }
    If ( $WPFMiscTweaksRightClickMenu.IsChecked -eq $true ) {
        Write-Host "Setting Classic Right-Click Menu..."
        Invoke-WinTweaks WPFMiscTweaksRightClickMenu
        $WPFMiscTweaksRightClickMenu.IsChecked = $false
    }
    If ( $WPFEssTweaksOO.IsChecked -eq $true ) {
        Write-Host "Running OO Shutup..."
        Invoke-WinTweaks WPFEssTweaksOO
        $WPFEssTweaksOO.IsChecked = $false
    }
    If ( $WPFEssTweaksRP.IsChecked -eq $true ) {
        Write-Host "Creating Restore Point in case something bad happens..."
        Invoke-WinTweaks WPFEssTweaksRP
        $WPFEssTweaksRP.IsChecked = $false
    }
    If ( $WPFEssTweaksServices.IsChecked -eq $true ) {
        Write-Host "Setting Services to Manual..."
        Invoke-WinTweaks WPFEssTweaksServices

        $WPFEssTweaksServices.IsChecked = $false
    }
    If ( $WPFEssTweaksStorage.IsChecked -eq $true ) {
        Write-Host "Disabling Storage Sense..."
        Invoke-WinTweaks WPFEssTweaksStorage
        $WPFEssTweaksStorage.IsChecked = $false
    }
    If ( $WPFEssTweaksTele.IsChecked -eq $true ) {
        Write-Host "Disabling Telemetry..."
        Invoke-WinTweaks WPFEssTweaksTele

        $WPFEssTweaksTele.IsChecked = $false
    }
    If ( $WPFEssTweaksWifi.IsChecked -eq $true ) {
        Write-Host "Disabling Wi-Fi Sense..."
        Invoke-WinTweaks WPFEssTweaksWifi
        $WPFEssTweaksWifi.IsChecked = $false
    }
    If ( $WPFMiscTweaksLapPower.IsChecked -eq $true ) {
        Write-Host "Enabling Power Throttling..."
        Invoke-WinTweaks WPFMiscTweaksLapPower
        $WPFMiscTweaksLapPower.IsChecked = $false
    }
    If ( $WPFMiscTweaksLapNum.IsChecked -eq $true ) {
        Write-Host "Disabling NumLock after startup..."
        Invoke-WinTweaks WPFMiscTweaksLapNum
        $WPFMiscTweaksLapNum.IsChecked = $false
    }
    If ( $WPFMiscTweaksPower.IsChecked -eq $true ) {
        Write-Host "Disabling Power Throttling..."
        Invoke-WinTweaks WPFMiscTweaksPower
        $WPFMiscTweaksPower.IsChecked = $false
    }
    If ( $WPFMiscTweaksNum.IsChecked -eq $true ) {
        Write-Host "Enabling NumLock after startup..."
        Invoke-WinTweaks WPFMiscTweaksNum
        $WPFMiscTweaksNum.IsChecked = $false
    }
    If ( $WPFMiscTweaksExt.IsChecked -eq $true ) {
        Write-Host "Showing known file extensions..."
        Invoke-WinTweaks WPFMiscTweaksExt
        $WPFMiscTweaksExt.IsChecked = $false
    }
    If ( $WPFMiscTweaksUTC.IsChecked -eq $true ) {
        Write-Host "Setting BIOS time to UTC..."
        Invoke-WinTweaks WPFMiscTweaksUTC
        $WPFMiscTweaksUTC.IsChecked = $false
    }
    If ( $WPFMiscTweaksDisplay.IsChecked -eq $true ) {
        Write-Host "Adjusting visual effects for performance..."
        Invoke-WinTweaks WPFMiscTweaksDisplay
        $WPFMiscTweaksDisplay.IsChecked = $false
    }
    If ( $WPFMiscTweaksDisableMouseAcceleration.IsChecked -eq $true ) {
        Write-Host "Disabling mouse acceleration..."
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Type String -Value 0
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Type String -Value 0
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Type String -Value 0
        $WPFMiscTweaksDisableMouseAcceleration.IsChecked = $false
    }
    If ( $WPFMiscTweaksEnableMouseAcceleration.IsChecked -eq $true ) {
        Write-Host "Enabling mouse acceleration..."
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Type String -Value 1
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Type String -Value 6
        Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Type String -Value 10
        $WPFMiscTweaksEnableMouseAcceleration.IsChecked = $false
    }
    If ( $WPFEssTweaksRemoveCortana.IsChecked -eq $true ) {
        Write-Host "Removing Cortana..."
        Get-AppxPackage -allusers Microsoft.549981C3F5F10 | Remove-AppxPackage
        $WPFEssTweaksRemoveCortana.IsChecked = $false
    }
    If ( $WPFEssTweaksRemoveEdge.IsChecked -eq $true ) {
        Write-Host "Removing Microsoft Edge..."
        Invoke-WebRequest -useb https://raw.githubusercontent.com/ChrisTitusTech/winutil/$BranchToUse/Edge_Removal.bat | Invoke-Expression
        $WPFEssTweaksRemoveEdge.IsChecked = $false
    }
    If ( $WPFEssTweaksDeBloat.IsChecked -eq $true ) {
        $Bloatware = @(
            #Unnecessary Windows 10 AppX Apps
            "3DBuilder"
            "Microsoft3DViewer"
            "AppConnector"
            "BingFinance"
            "BingNews"
            "BingSports"
            "BingTranslator"
            "BingWeather"
            "BingFoodAndDrink"
            "BingHealthAndFitness"
            "BingTravel"
            "MinecraftUWP"
            "GamingServices"
            # "WindowsReadingList"
            "GetHelp"
            "Getstarted"
            "Messaging"
            "Microsoft3DViewer"
            "MicrosoftSolitaireCollection"
            "NetworkSpeedTest"
            "News"
            "Lens"
            "Sway"
            "OneNote"
            "OneConnect"
            "People"
            "Print3D"
            "SkypeApp"
            "Todos"
            "Wallet"
            "Whiteboard"
            "WindowsAlarms"
            "windowscommunicationsapps"
            "WindowsFeedbackHub"
            "WindowsMaps"
            "WindowsPhone"
            "WindowsSoundRecorder"
            "XboxApp"
            "ConnectivityStore"
            "CommsPhone"
            "ScreenSketch"
            "TCUI"
            "XboxGameOverlay"
            "XboxGameCallableUI"
            "XboxSpeechToTextOverlay"
            "MixedReality.Portal"
            "ZuneMusic"
            "ZuneVideo"
            #"YourPhone"
            "Getstarted"
            "MicrosoftOfficeHub"

            #Sponsored Windows 10 AppX Apps
            #Add sponsored/featured apps to remove in the "*AppName*" format
            "EclipseManager"
            "ActiproSoftwareLLC"
            "AdobeSystemsIncorporated.AdobePhotoshopExpress"
            "Duolingo-LearnLanguagesforFree"
            "PandoraMediaInc"
            "CandyCrush"
            "BubbleWitch3Saga"
            "Wunderlist"
            "Flipboard"
            "Twitter"
            "Facebook"
            "Royal Revolt"
            "Sway"
            "Speed Test"
            "Dolby"
            "Viber"
            "ACGMediaPlayer"
            "Netflix"
            "OneCalendar"
            "LinkedInforWindows"
            "HiddenCityMysteryofShadows"
            "Hulu"
            "HiddenCity"
            "AdobePhotoshopExpress"
            "HotspotShieldFreeVPN"

            #Optional: Typically not removed but you can if you need to
            "Advertising"
            #"MSPaint"
            #"MicrosoftStickyNotes"
            #"Windows.Photos"
            #"WindowsCalculator"
            #"WindowsStore"

            # HPBloatware Packages
            "HPJumpStarts"
            "HPPCHardwareDiagnosticsWindows"
            "HPPowerManager"
            "HPPrivacySettings"
            "HPSupportAssistant"
            "HPSureShieldAI"
            "HPSystemInformation"
            "HPQuickDrop"
            "HPWorkWell"
            "myHP"
            "HPDesktopSupportUtilities"
            "HPQuickTouch"
            "HPEasyClean"
            "HPSystemInformation"
        )

        ## Teams Removal - Source: https://github.com/asheroto/UninstallTeams
        function getUninstallString($match) {
            return (Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$match*" }).UninstallString
        }

        $TeamsPath = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft', 'Teams')
        $TeamsUpdateExePath = [System.IO.Path]::Combine($TeamsPath, 'Update.exe')

        Write-Host "Stopping Teams process..."
        Stop-Process -Name "*teams*" -Force -ErrorAction SilentlyContinue

        Write-Host "Uninstalling Teams from AppData\Microsoft\Teams"
        if ([System.IO.File]::Exists($TeamsUpdateExePath)) {
            # Uninstall app
            $proc = Start-Process $TeamsUpdateExePath "-uninstall -s" -PassThru
            $proc.WaitForExit()
        }

        Write-Host "Removing Teams AppxPackage..."
        Get-AppxPackage "*Teams*" | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxPackage "*Teams*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

        Write-Host "Deleting Teams directory"
        if ([System.IO.Directory]::Exists($TeamsPath)) {
            Remove-Item $TeamsPath -Force -Recurse -ErrorAction SilentlyContinue
        }

        Write-Host "Deleting Teams uninstall registry key"
        # Uninstall from Uninstall registry key UninstallString
        $us = getUninstallString("Teams");
        if ($us.Length -gt 0) {
            $us = ($us.Replace("/I", "/uninstall ") + " /quiet").Replace("  ", " ")
            $FilePath = ($us.Substring(0, $us.IndexOf(".exe") + 4).Trim())
            $ProcessArgs = ($us.Substring($us.IndexOf(".exe") + 5).Trim().replace("  ", " "))
            $proc = Start-Process -FilePath $FilePath -Args $ProcessArgs -PassThru
            $proc.WaitForExit()
        }

        Write-Host "Restart computer to complete teams uninstall"

        Write-Host "Removing Bloatware"

        foreach ($Bloat in $Bloatware) {
            Get-AppxPackage "*$Bloat*" | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*$Bloat*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
            Write-Host "Trying to remove $Bloat."
        }

        Write-Host "Finished Removing Bloatware Apps"
        Write-Host "Removing Bloatware Programs"
        # Remove installed programs
        $InstalledPrograms = Get-Package | Where-Object { $UninstallPrograms -contains $_.Name }
        $InstalledPrograms | ForEach-Object {

            Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."

            Try {
                $Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction SilentlyContinue
                Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
            }
            Catch {
                Write-Warning -Message "Failed to uninstall: [$($_.Name)]"
            }
        }
        Write-Host "Finished Removing Bloatware Programs"
        $WPFEssTweaksDeBloat.IsChecked = $false
    }

    Write-Host "================================="
    Write-Host "--     Tweaks are Finished    ---"
    Write-Host "================================="

    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageboxTitle = "Tweaks are Finished "
    $Messageboxbody = ("Done")
    $MessageIcon = [System.Windows.MessageBoxImage]::Information

    [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)
})

$WPFAddUltPerf.Add_Click({
        Write-Host "Adding Ultimate Performance Profile"
        powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
        Write-Host "Profile added"
     }
)

$WPFRemoveUltPerf.Add_Click({
        Write-Host "Removing Ultimate Performance Profile"
        powercfg -delete e9a42b02-d5df-448d-aa00-03f14749eb61
        Write-Host "Profile Removed"
     }
)

function Get-AppsUseLightTheme{
    return (Get-ItemProperty -path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize').AppsUseLightTheme
}

function Get-SystemUsesLightTheme{
    return (Get-ItemProperty -path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize').SystemUsesLightTheme
}

$WPFToggleDarkMode.IsChecked = $(If ($(Get-AppsUseLightTheme) -eq 0 -And $(Get-SystemUsesLightTheme) -eq 0) {$true} Else {$false})

$WPFToggleDarkMode.Add_Click({
    $EnableDarkMode = $WPFToggleDarkMode.IsChecked
    $DarkMoveValue = $(If ( $EnableDarkMode ) {0} Else {1})
    Write-Host $(If ( $EnableDarkMode ) {"Enabling Dark Mode"} Else {"Disabling Dark Mode"})
    $Theme = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    If ($DarkMoveValue -ne $(Get-AppsUseLightTheme))
    {
        Set-ItemProperty $Theme AppsUseLightTheme -Value $DarkMoveValue
    }
    If ($DarkMoveValue -ne $(Get-SystemUsesLightTheme))
    {
        Set-ItemProperty $Theme SystemUsesLightTheme -Value $DarkMoveValue
    }
    Write-Host $(If ( $EnableDarkMode ) {"Enabled"} Else {"Disabled"})

    }
)

#===========================================================================
# Undo All
#===========================================================================
$WPFundoall.Add_Click({
        Write-Host "Creating Restore Point in case something bad happens"
        Enable-ComputerRestore -Drive "$env:SystemDrive"
        Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS"

        Write-Host "Enabling Telemetry..."
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 1
        Write-Host "Enabling Wi-Fi Sense"
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Type DWord -Value 1
        Write-Host "Enabling Application suggestions..."
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OemPreInstalledAppsEnabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEverEnabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353698Enabled" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Type DWord -Value 1
        If (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent") {
            Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Type DWord -Value 0
        Write-Host "Enabling Activity History..."
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Type DWord -Value 1
        Write-Host "Enable Location Tracking..."
        If (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location") {
            Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Type String -Value "Allow"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value 1
        Write-Host "Enabling automatic Maps updates..."
        Set-ItemProperty -Path "HKLM:\SYSTEM\Maps" -Name "AutoUpdateEnabled" -Type DWord -Value 1
        Write-Host "Enabling Feedback..."
        If (Test-Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules") {
            Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Type DWord -Value 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Type DWord -Value 0
        Write-Host "Enabling Tailored Experiences..."
        If (Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent") {
            Remove-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Type DWord -Value 0
        Write-Host "Disabling Advertising ID..."
        If (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo") {
            Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Type DWord -Value 0
        Write-Host "Allow Error reporting..."
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Type DWord -Value 0
        Write-Host "Allowing Diagnostics Tracking Service..."
        Stop-Service "DiagTrack" -WarningAction SilentlyContinue
        Set-Service "DiagTrack" -StartupType Manual
        Write-Host "Allowing WAP Push Service..."
        Stop-Service "dmwappushservice" -WarningAction SilentlyContinue
        Set-Service "dmwappushservice" -StartupType Manual
        Write-Host "Allowing Home Groups services..."
        Stop-Service "HomeGroupListener" -WarningAction SilentlyContinue
        Set-Service "HomeGroupListener" -StartupType Manual
        Stop-Service "HomeGroupProvider" -WarningAction SilentlyContinue
        Set-Service "HomeGroupProvider" -StartupType Manual
        Write-Host "Enabling Storage Sense..."
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" | Out-Null
        Write-Host "Allowing Superfetch service..."
        Stop-Service "SysMain" -WarningAction SilentlyContinue
        Set-Service "SysMain" -StartupType Manual
        Write-Host "Setting BIOS time to Local Time instead of UTC..."
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Type DWord -Value 0
        Write-Host "Enabling Hibernation..."
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernteEnabled" -Type Dword -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Type Dword -Value 1
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -ErrorAction SilentlyContinue

        Write-Host "Hiding file operations details..."
        If (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager") {
            Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Recurse -ErrorAction SilentlyContinue
        }
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Name "EnthusiastMode" -Type DWord -Value 0
        Write-Host "Showing Task View button..."
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Type DWord -Value 1

        Write-Host "Changing default Explorer view to Quick Access..."
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Type DWord -Value 0

        Write-Host "Unrestricting AutoLogger directory"
        $autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
        icacls $autoLoggerDir /grant:r SYSTEM:`(OI`)`(CI`)F | Out-Null

        Write-Host "Enabling and starting Diagnostics Tracking Service"
        Set-Service "DiagTrack" -StartupType Automatic
        Start-Service "DiagTrack"

        Write-Host "Hiding known file extensions"
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Type DWord -Value 1

        Write-Host "Reset Local Group Policies to Stock Defaults"
        # cmd /c secedit /configure /cfg %windir%\inf\defltbase.inf /db defltbase.sdb /verbose
        cmd /c RD /S /Q "%WinDir%\System32\GroupPolicyUsers"
        cmd /c RD /S /Q "%WinDir%\System32\GroupPolicy"
        cmd /c gpupdate /force
        # Considered using Invoke-GPUpdate but requires module most people won't have installed

        Write-Host "Adjusting visual effects for appearance..."
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Type String -Value 1
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value 400
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Type Binary -Value ([byte[]](158, 30, 7, 128, 18, 0, 0, 0))
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value 1
        Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Type DWord -Value 3
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Type DWord -Value 1
        Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -ErrorAction SilentlyContinue
        Write-Host "Restoring Clipboard History..."
        Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Clipboard" -Name "EnableClipboardHistory" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowClipboardHistory" -ErrorAction SilentlyContinue
        Write-Host "Enabling Notifications and Action Center"
        Remove-Item -Path HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer -Force
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled"
        Write-Host "Restoring Default Right Click Menu Layout"
        Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Confirm:$false -Force

        Write-Host "Reset News and Interests"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" -Name "EnableFeeds" -Type DWord -Value 1
        # Remove "News and Interest" from taskbar
        Set-ItemProperty -Path  "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds" -Name "ShellFeedsTaskbarViewMode" -Type DWord -Value 0
        Write-Host "Done - Reverted to Stock Settings"

        Write-Host "Essential Undo Completed"

        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = "Undo All"
        $Messageboxbody = ("Done")
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)

        Write-Host "================================="
        Write-Host "---   Undo All is Finished    ---"
        Write-Host "================================="
    })
#===========================================================================
# Tab 3 - Config Buttons
#===========================================================================
$WPFFeatureInstall.Add_Click({

        If ( $WPFFeaturesdotnet.IsChecked -eq $true ) {
            Enable-WindowsOptionalFeature -Online -FeatureName "NetFx4-AdvSrvs" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" -All -NoRestart
        }
        If ( $WPFFeatureshyperv.IsChecked -eq $true ) {
            Enable-WindowsOptionalFeature -Online -FeatureName "HypervisorPlatform" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-All" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Tools-All" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Management-PowerShell" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Hypervisor" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Services" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-Management-Clients" -All -NoRestart
            cmd /c bcdedit /set hypervisorschedulertype classic
            Write-Host "HyperV is now installed and configured. Please Reboot before using."
        }
        If ( $WPFFeatureslegacymedia.IsChecked -eq $true ) {
            Enable-WindowsOptionalFeature -Online -FeatureName "WindowsMediaPlayer" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "MediaPlayback" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "DirectPlay" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "LegacyComponents" -All -NoRestart
        }
        If ( $WPFFeaturewsl.IsChecked -eq $true ) {
            Enable-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Windows-Subsystem-Linux" -All -NoRestart
            Write-Host "WSL is now installed and configured. Please Reboot before using."
        }
        If ( $WPFFeaturenfs.IsChecked -eq $true ) {
            Enable-WindowsOptionalFeature -Online -FeatureName "ServicesForNFS-ClientOnly" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "ClientForNFS-Infrastructure" -All -NoRestart
            Enable-WindowsOptionalFeature -Online -FeatureName "NFS-Administration" -All -NoRestart
            nfsadmin client stop
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default" -Name "AnonymousUID" -Type DWord -Value 0
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ClientForNFS\CurrentVersion\Default" -Name "AnonymousGID" -Type DWord -Value 0
            nfsadmin client start
            nfsadmin client localhost config fileaccess=755 SecFlavors=+sys -krb5 -krb5i
            Write-Host "NFS is now setup for user based NFS mounts"
        }
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = "All features are now installed "
        $Messageboxbody = ("Done")
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)

        Write-Host "================================="
        Write-Host "---  Features are Installed   ---"
        Write-Host "================================="
    })

$WPFPanelDISM.Add_Click({
        Start-Process PowerShell -ArgumentList "Write-Host '(1/4) Chkdsk' -ForegroundColor Green; Chkdsk /scan;
        Write-Host '`n(2/4) SFC - 1st scan' -ForegroundColor Green; sfc /scannow;
        Write-Host '`n(3/4) DISM' -ForegroundColor Green; DISM /Online /Cleanup-Image /Restorehealth;
        Write-Host '`n(4/4) SFC - 2nd scan' -ForegroundColor Green; sfc /scannow;
        Read-Host '`nPress Enter to Continue'" -verb runas
    })
$WPFPanelAutologin.Add_Click({
        curl.exe -ss "https://live.sysinternals.com/Autologon.exe" -o autologin.exe # Official Microsoft recommendation https://learn.microsoft.com/en-us/sysinternals/downloads/autologon
        cmd /c autologin.exe
    })
$WPFPanelcontrol.Add_Click({
        cmd /c control
    })
$WPFPanelnetwork.Add_Click({
        cmd /c ncpa.cpl
    })
$WPFPanelpower.Add_Click({
        cmd /c powercfg.cpl
    })
$WPFPanelsound.Add_Click({
        cmd /c mmsys.cpl
    })
$WPFPanelsystem.Add_Click({
        cmd /c sysdm.cpl
    })
$WPFPaneluser.Add_Click({
        cmd /c "control userpasswords2"
    })
#===========================================================================
# Tab 4 - Updates Buttons
#===========================================================================

$WPFUpdatesdefault.Add_Click({
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Type DWord -Value 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Type DWord -Value 3
        If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config")) {
            New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 1

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
        Write-Host "================================="
        Write-Host "---  Updates Set to Default   ---"
        Write-Host "================================="
    })

$WPFFixesUpdate.Add_Click({
        ### Reset Windows Update Script - reregister dlls, services, and remove registry entires.
        Write-Host "1. Stopping Windows Update Services..."
        Stop-Service -Name BITS
        Stop-Service -Name wuauserv
        Stop-Service -Name appidsvc
        Stop-Service -Name cryptsvc

        Write-Host "2. Remove QMGR Data file..."
        Remove-Item "$env:allusersprofile\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -ErrorAction SilentlyContinue

        Write-Host "3. Renaming the Software Distribution and CatRoot Folder..."
        Rename-Item $env:systemroot\SoftwareDistribution SoftwareDistribution.bak -ErrorAction SilentlyContinue
        Rename-Item $env:systemroot\System32\Catroot2 catroot2.bak -ErrorAction SilentlyContinue

        Write-Host "4. Removing old Windows Update log..."
        Remove-Item $env:systemroot\WindowsUpdate.log -ErrorAction SilentlyContinue

        Write-Host "5. Resetting the Windows Update Services to defualt settings..."
        "sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"
        "sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)"
        Set-Location $env:systemroot\system32

        Write-Host "6. Registering some DLLs..."
        regsvr32.exe /s atl.dll
        regsvr32.exe /s urlmon.dll
        regsvr32.exe /s mshtml.dll
        regsvr32.exe /s shdocvw.dll
        regsvr32.exe /s browseui.dll
        regsvr32.exe /s jscript.dll
        regsvr32.exe /s vbscript.dll
        regsvr32.exe /s scrrun.dll
        regsvr32.exe /s msxml.dll
        regsvr32.exe /s msxml3.dll
        regsvr32.exe /s msxml6.dll
        regsvr32.exe /s actxprxy.dll
        regsvr32.exe /s softpub.dll
        regsvr32.exe /s wintrust.dll
        regsvr32.exe /s dssenh.dll
        regsvr32.exe /s rsaenh.dll
        regsvr32.exe /s gpkcsp.dll
        regsvr32.exe /s sccbase.dll
        regsvr32.exe /s slbcsp.dll
        regsvr32.exe /s cryptdlg.dll
        regsvr32.exe /s oleaut32.dll
        regsvr32.exe /s ole32.dll
        regsvr32.exe /s shell32.dll
        regsvr32.exe /s initpki.dll
        regsvr32.exe /s wuapi.dll
        regsvr32.exe /s wuaueng.dll
        regsvr32.exe /s wuaueng1.dll
        regsvr32.exe /s wucltui.dll
        regsvr32.exe /s wups.dll
        regsvr32.exe /s wups2.dll
        regsvr32.exe /s wuweb.dll
        regsvr32.exe /s qmgr.dll
        regsvr32.exe /s qmgrprxy.dll
        regsvr32.exe /s wucltux.dll
        regsvr32.exe /s muweb.dll
        regsvr32.exe /s wuwebv.dll

        Write-Host "7) Removing WSUS client settings..."
        REG DELETE "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v AccountDomainSid /f
        REG DELETE "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v PingID /f
        REG DELETE "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate" /v SusClientId /f

        Write-Host "8) Resetting the WinSock..."
        netsh winsock reset
        netsh winhttp reset proxy
        netsh int ip reset

        Write-Host "9) Delete all BITS jobs..."
        Get-BitsTransfer | Remove-BitsTransfer

        Write-Host "10) Attempting to install the Windows Update Agent..."
        If ([System.Environment]::Is64BitOperatingSystem) {
            wusa Windows8-RT-KB2937636-x64 /quiet
        }
        else {
            wusa Windows8-RT-KB2937636-x86 /quiet
        }

        Write-Host "11) Starting Windows Update Services..."
        Start-Service -Name BITS
        Start-Service -Name wuauserv
        Start-Service -Name appidsvc
        Start-Service -Name cryptsvc

        Write-Host "12) Forcing discovery..."
        wuauclt /resetauthorization /detectnow

        Write-Host "Process complete. Please reboot your computer."

        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = "Reset Windows Update "
        $Messageboxbody = ("Stock settings loaded.`n Please reboot your computer")
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)
        Write-Host "================================="
        Write-Host "-- Reset ALL Updates to Factory -"
        Write-Host "================================="
    })

$WPFUpdatesdisable.Add_Click({
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Type DWord -Value 1
        If (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config")) {
            New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Type DWord -Value 0

        $services = @(
            "BITS"
            "wuauserv"
        )

        foreach ($service in $services) {
            # -ErrorAction SilentlyContinue is so it doesn't write an error to stdout if a service doesn't exist

            Write-Host "Setting $service StartupType to Disabled"
            Get-Service -Name $service -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled
        }
        Write-Host "================================="
        Write-Host "---  Updates ARE DISABLED     ---"
        Write-Host "================================="
    })
$WPFUpdatessecurity.Add_Click({
        Write-Host "Disabling driver offering through Windows Update..."
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" -Name "PreventDeviceMetadataFromNetwork" -Type DWord -Value 1
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontPromptForWindowsUpdate" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DontSearchWindowsUpdate" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "DriverUpdateWizardWuSearchEnabled" -Type DWord -Value 0
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "ExcludeWUDriversInQualityUpdate" -Type DWord -Value 1
        Write-Host "Disabling Windows Update automatic restart..."
        If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
        }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -Type DWord -Value 0
        Write-Host "Disabled driver offering through Windows Update"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "BranchReadinessLevel" -Type DWord -Value 20
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferFeatureUpdatesPeriodInDays" -Type DWord -Value 365
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "DeferQualityUpdatesPeriodInDays " -Type DWord -Value 4

        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageboxTitle = "Set Security Updates"
        $Messageboxbody = ("Recommended Update settings loaded")
        $MessageIcon = [System.Windows.MessageBoxImage]::Information

        [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)
        Write-Host "================================="
        Write-Host "-- Updates Set to Recommended ---"
        Write-Host "================================="
    })

#===========================================================================
# Setup runspace and background config
#===========================================================================

$runspace = [RunspaceFactory]::CreateRunspace()
$runspace.ApartmentState = "STA"
$runspace.ThreadOptions = "ReuseThread"
$runspace.Open()
$runspace.SessionStateProxy.SetVariable("sync", $sync)

#Load information in the background
Invoke-Runspace -ScriptBlock {
    $sync.ConfigLoaded = $False

    $sync.configs = @{}
    $ConfigsToLoad = @(
        "applications",
        "tweaks",
        "preset",
        "feature",
        "dns"
    )

    $ConfigsToLoad | ForEach-Object {
        $sync.configs["$psitem"] = [System.Net.WebClient]::new().DownloadStringTaskAsync("https://raw.githubusercontent.com/ChrisTitusTech/winutil/$($Sync.BranchToUse)/config/$psitem.json")
    }

    $sync.ComputerInfo = Get-ComputerInfo

    $ConfigsToLoad | ForEach-Object {
        $sync.configs["$psitem"] = ConvertFrom-Json ($sync.configs["$psitem"].GetAwaiter().GetResult())
    }

    #Uncomment to force local files
    $ConfigsToLoad | ForEach-Object {
        $sync.configs["$psitem"] = Get-Content "$($sync.PSScriptRoot)\config\$PSItem.json" | ConvertFrom-Json
    } 
    
    $sync.ConfigLoaded = $True
} | Out-Null

#===========================================================================
# Shows the form
#===========================================================================
Get-FormVariables

try{
    Install-Choco
}
Catch [ChocoFailedInstall]{
    Write-Host "==========================================="
    Write-Host "--    Chocolatey failed to install      ---"
    Write-Host "==========================================="
}

$Form.ShowDialog() | out-null
Stop-Transcript
