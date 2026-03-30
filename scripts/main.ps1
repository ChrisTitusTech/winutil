# Create enums
Add-Type @"
public enum PackageManagers
{
    Winget,
    Choco
}
"@

# SPDX-License-Identifier: MIT
# Set the maximum number of threads for the RunspacePool to the number of threads on the machine
$maxthreads = [int]$env:NUMBER_OF_PROCESSORS

# Create a new session state for parsing variables into our runspace
$hashVars = New-object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'sync',$sync,$Null
$debugVar = New-object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'DebugPreference',$DebugPreference,$Null
$uiVar = New-object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'PARAM_NOUI',$PARAM_NOUI,$Null
$offlineVar = New-object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'PARAM_OFFLINE',$PARAM_OFFLINE,$Null
$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

# Add the variable to the session state
$InitialSessionState.Variables.Add($hashVars)
$InitialSessionState.Variables.Add($debugVar)
$InitialSessionState.Variables.Add($uiVar)
$InitialSessionState.Variables.Add($offlineVar)

# Get every private function and add them to the session state
$functions = Get-ChildItem function:\ | Where-Object { $_.Name -imatch 'winutil|WPF' }
foreach ($function in $functions) {
    $functionDefinition = Get-Content function:\$($function.name)
    $functionEntry = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $($function.name), $functionDefinition

    $initialSessionState.Commands.Add($functionEntry)
}

# Create the runspace pool
$sync.runspace = [runspacefactory]::CreateRunspacePool(
    1,                      # Minimum thread count
    $maxthreads,            # Maximum thread count
    $InitialSessionState,   # Initial session state
    $Host                   # Machine to create runspaces on
)

# Open the RunspacePool instance
$sync.runspace.Open()

# Create classes for different exceptions

class WingetFailedInstall : Exception {
    [string]$additionalData
    WingetFailedInstall($Message) : base($Message) {}
}

class ChocoFailedInstall : Exception {
    [string]$additionalData
    ChocoFailedInstall($Message) : base($Message) {}
}

class GenericException : Exception {
    [string]$additionalData
    GenericException($Message) : base($Message) {}
}

# Load the configuration files

$sync.configs.applicationsHashtable = @{}
$sync.configs.applications.PSObject.Properties | ForEach-Object {
    $sync.configs.applicationsHashtable[$_.Name] = $_.Value
}

Set-Preferences

if ($PARAM_NOUI) {
    Show-CTTLogo
    if ($PARAM_CONFIG -and -not [string]::IsNullOrWhiteSpace($PARAM_CONFIG)) {
        Write-Host "Running config file tasks..."
        Invoke-WPFImpex -type "import" -Config $PARAM_CONFIG
        if ($PARAM_RUN) {
            Invoke-WinUtilAutoRun
        }
        else {
            Write-Host "Did you forget to add '--Run'?";
        }
        $sync.runspace.Dispose()
        $sync.runspace.Close()
        [System.GC]::Collect()
        Stop-Transcript
        exit 1
    }
    else {
        Write-Host "Cannot automatically run without a config file provided."
        $sync.runspace.Dispose()
        $sync.runspace.Close()
        [System.GC]::Collect()
        Stop-Transcript
        exit 1
    }
}

$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'

# Localize common static XAML strings before parsing
try {
    $lang = $sync.preferences.language
    $val = Get-LocalizedString -Key 'ThemeButtonTooltip' -Language $lang
    if ($val) {
        $escaped = $val -replace '"','&quot;'
        $inputXML = $inputXML.Replace('ToolTip="Change the Winutil UI Theme"', 'ToolTip="' + $escaped + '"')
    }

    $val = Get-LocalizedString -Key 'Auto' -Language $lang
    if ($val) { $inputXML = $inputXML.Replace('Header="Auto"', 'Header="' + ($val -replace '"','&quot;') + '"') }
    $val = Get-LocalizedString -Key 'Dark' -Language $lang
    if ($val) { $inputXML = $inputXML.Replace('Header="Dark"', 'Header="' + ($val -replace '"','&quot;') + '"') }
    $val = Get-LocalizedString -Key 'Light' -Language $lang
    if ($val) { $inputXML = $inputXML.Replace('Header="Light"', 'Header="' + ($val -replace '"','&quot;') + '"') }

    $val = Get-LocalizedString -Key 'AutoTooltip' -Language $lang
    if ($val) { $inputXML = $inputXML.Replace('Content="Follow the Windows Theme"', 'Content="' + ($val -replace '"','&quot;') + '"') }
    $val = Get-LocalizedString -Key 'DarkTooltip' -Language $lang
    if ($val) { $inputXML = $inputXML.Replace('Content="Use Dark Theme"', 'Content="' + ($val -replace '"','&quot;') + '"') }
    $val = Get-LocalizedString -Key 'LightTooltip' -Language $lang
    if ($val) { $inputXML = $inputXML.Replace('Content="Use Light Theme"', 'Content="' + ($val -replace '"','&quot;') + '"') }

    $val = Get-LocalizedString -Key 'FontScalingTooltip' -Language $lang
    if ($val) { $inputXML = $inputXML.Replace('ToolTip="Adjust Font Scaling for Accessibility"', 'ToolTip="' + ($val -replace '"','&quot;') + '"') }

    $val = Get-LocalizedString -Key 'SearchTooltip' -Language $lang
    if ($val) { $inputXML = $inputXML.Replace('ToolTip="Press Ctrl-F and type app name to filter application list below. Press Esc to reset the filter"', 'ToolTip="' + ($val -replace '"','&quot;') + '"') }

    $val = Get-LocalizedString -Key 'LanguageLabel' -Language $lang
    if ($val) { $inputXML = $inputXML.Replace('>Language:</TextBlock>', '>' + ($val -replace '"','&quot;') + '</TextBlock>') }

    $val = Get-LocalizedString -Key 'About' -Language $lang
    if ($val) { $inputXML = $inputXML.Replace('Header="About"', 'Header="' + ($val -replace '"','&quot;') + '"') }

    $val = Get-LocalizedString -Key 'Documentation' -Language $lang
    if ($val) { $inputXML = $inputXML.Replace('Header="Documentation"', 'Header="' + ($val -replace '"','&quot;') + '"') }

    $val = Get-LocalizedString -Key 'Sponsors' -Language $lang
    if ($val) { $inputXML = $inputXML.Replace('Header="Sponsors"', 'Header="' + ($val -replace '"','&quot;') + '"') }

    $val = Get-LocalizedString -Key 'OpenMicrosoftDownloadPage' -Language $lang
    if ($val) { $inputXML = $inputXML.Replace('Content="Open Microsoft Download Page"', 'Content="' + ($val -replace '"','&quot;') + '"') }

} catch {
    Write-Debug "XAML localization replacements failed: $_"
}

[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML

# Read the XAML file
$readerOperationSuccessful = $false # There's more cases of failure then success.
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $sync["Form"] = [Windows.Markup.XamlReader]::Load( $reader )
    $readerOperationSuccessful = $true
} catch [System.Management.Automation.MethodInvocationException] {
    Write-Host "We ran into a problem with the XAML code.  Check the syntax for this control..." -ForegroundColor Red
    Write-Host $error[0].Exception.Message -ForegroundColor Red

    If ($error[0].Exception.Message -like "*button*") {
        write-Host "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n" -ForegroundColor Red
    }
} catch {
    Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed." -ForegroundColor Red
}

if (-NOT ($readerOperationSuccessful)) {
    Write-Host "Failed to parse xaml content using Windows.Markup.XamlReader's Load Method." -ForegroundColor Red
    Write-Host "Quitting winutil..." -ForegroundColor Red
    $sync.runspace.Dispose()
    $sync.runspace.Close()
    [System.GC]::Collect()
    exit 1
}

# Setup the Window to follow listen for windows Theme Change events and update the winutil theme
# throttle logic needed, because windows seems to send more than one theme change event per change
$lastThemeChangeTime = [datetime]::MinValue
$debounceInterval = [timespan]::FromSeconds(2)
$sync.Form.Add_Loaded({
    $interopHelper = New-Object System.Windows.Interop.WindowInteropHelper $sync.Form
    $hwndSource = [System.Windows.Interop.HwndSource]::FromHwnd($interopHelper.Handle)
    $hwndSource.AddHook({
        param (
            [System.IntPtr]$hwnd,
            [int]$msg,
            [System.IntPtr]$wParam,
            [System.IntPtr]$lParam,
            [ref]$handled
        )
        # Check for the Event WM_SETTINGCHANGE (0x1001A) and validate that Button shows the icon for "Auto" => [char]0xF08C
        if (($msg -eq 0x001A) -and $sync.ThemeButton.Content -eq [char]0xF08C) {
            $currentTime = [datetime]::Now
            if ($currentTime - $lastThemeChangeTime -gt $debounceInterval) {
                Invoke-WinutilThemeChange -theme "Auto"
                $script:lastThemeChangeTime = $currentTime
                $handled = $true
            }
        }
        return 0
    })
})

Invoke-WinutilThemeChange -theme $sync.preferences.theme


# Now call the function with the final merged config
Invoke-WPFUIElements -configVariable $sync.configs.appnavigation -targetGridName "appscategory" -columncount 1
Initialize-WPFUI -targetGridName "appscategory"

Initialize-WPFUI -targetGridName "appspanel"

Invoke-WPFUIElements -configVariable $sync.configs.tweaks -targetGridName "tweakspanel" -columncount 2

Invoke-WPFUIElements -configVariable $sync.configs.feature -targetGridName "featurespanel" -columncount 2

# Future implementation: Add Windows Version to updates panel
#Invoke-WPFUIElements -configVariable $sync.configs.updates -targetGridName "updatespanel" -columncount 1

#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {$sync["$("$($psitem.Name)")"] = $sync["Form"].FindName($psitem.Name)}

#Persist Package Manager preference across winutil restarts
$sync.ChocoRadioButton.Add_Checked({
    $sync.preferences.packagemanager = [PackageManagers]::Choco
    Set-Preferences -save
})
$sync.WingetRadioButton.Add_Checked({
    $sync.preferences.packagemanager = [PackageManagers]::Winget
    Set-Preferences -save
})

switch ($sync.preferences.packagemanager) {
    "Choco" {$sync.ChocoRadioButton.IsChecked = $true; break}
    "Winget" {$sync.WingetRadioButton.IsChecked = $true; break}
}

function Set-LocalizedControlValue {
    param(
        [Parameter(Mandatory=$true)]$Control,
        [Parameter(Mandatory=$true)][string]$Property,
        [Parameter(Mandatory=$true)][string]$Key,
        [string]$Language
    )

    if (-not $Control) { return }

    $value = Get-LocalizedString -Key $Key -Language $Language
    if ($null -eq $value) { return }

    try {
        switch ($Property) {
            'Text' { $Control.Text = $value }
            'Content' { $Control.Content = $value }
            'Header' { $Control.Header = $value }
            'ToolTip' { $Control.ToolTip = $value }
        }
    } catch {
        Write-Debug "Failed to localize control property $Property using key '$Key': $_"
    }
}

function Bind-InstallSidebarEvents {
    param()

    if ($sync.ChocoRadioButton) {
        $sync.ChocoRadioButton.Add_Checked({
            $sync.preferences.packagemanager = [PackageManagers]::Choco
            Set-Preferences -save
        })
    }

    if ($sync.WingetRadioButton) {
        $sync.WingetRadioButton.Add_Checked({
            $sync.preferences.packagemanager = [PackageManagers]::Winget
            Set-Preferences -save
        })
    }

    switch ($sync.preferences.packagemanager) {
        "Choco" { if ($sync.ChocoRadioButton) { $sync.ChocoRadioButton.IsChecked = $true } }
        "Winget" { if ($sync.WingetRadioButton) { $sync.WingetRadioButton.IsChecked = $true } }
    }

    foreach ($entry in $sync.configs.appnavigation.PSObject.Properties) {
        $control = $sync[$entry.Name]
        if ($control -and $control.GetType().Name -eq "Button") {
            $control.Add_Click({
                [System.Object]$Sender = $args[0]
                Invoke-WPFButton $Sender.Name
            })
        }
    }
}

function Bind-SharedControlEvents {
    param()

    $sync.keys | ForEach-Object {
        if($sync.$psitem) {
            if($($sync["$psitem"].GetType() | Select-Object -ExpandProperty Name) -eq "ToggleButton") {
                $sync["$psitem"].Add_Click({
                    [System.Object]$Sender = $args[0]
                    Invoke-WPFButton $Sender.name
                })
            }

            if($($sync["$psitem"].GetType() | Select-Object -ExpandProperty Name) -eq "Button") {
                $sync["$psitem"].Add_Click({
                    [System.Object]$Sender = $args[0]
                    Invoke-WPFButton $Sender.name
                })
            }

            if ($($sync["$psitem"].GetType() | Select-Object -ExpandProperty Name) -eq "TextBlock") {
                if ($sync["$psitem"].Name.EndsWith("Link")) {
                    $sync["$psitem"].Add_MouseUp({
                        [System.Object]$Sender = $args[0]
                        Start-Process $Sender.ToolTip -ErrorAction Stop
                        Write-Debug "Opening: $($Sender.ToolTip)"
                    })
                }
            }
        }
    }
}

function Refresh-InstallTabUI {
    param()

    $selectedApps = @($sync.selectedApps)
    $selectedTweaks = @($sync.selectedTweaks)
    $selectedFeatures = @($sync.selectedFeatures)
    $selectedToggles = @($sync.selectedToggles)
    $highlightFoss = if ($sync.WPFToggleFOSSHighlight) { [bool]$sync.WPFToggleFOSSHighlight.IsChecked } else { $true }

    Invoke-WPFUIElements -configVariable $sync.configs.appnavigation -targetGridName "appscategory" -columncount 1
    Initialize-WPFUI -targetGridName "appscategory"
    Initialize-WPFUI -targetGridName "appspanel"
    Bind-InstallSidebarEvents

    $sync.selectedApps = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $selectedApps) { [void]$sync.selectedApps.Add([string]$item) }
    $sync.selectedTweaks = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $selectedTweaks) { [void]$sync.selectedTweaks.Add([string]$item) }
    $sync.selectedFeatures = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $selectedFeatures) { [void]$sync.selectedFeatures.Add([string]$item) }
    $sync.selectedToggles = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $selectedToggles) { [void]$sync.selectedToggles.Add([string]$item) }

    Reset-WPFCheckBoxes

    if ($sync.WPFToggleFOSSHighlight) {
        $sync.WPFToggleFOSSHighlight.IsChecked = $highlightFoss
    }
}

function Refresh-PreferencePanelsUI {
    param()

    Invoke-WPFUIElements -configVariable $sync.configs.tweaks -targetGridName "tweakspanel" -columncount 2
    Invoke-WPFUIElements -configVariable $sync.configs.feature -targetGridName "featurespanel" -columncount 2
    Bind-SharedControlEvents
    Reset-WPFCheckBoxes -doToggles $true
}

# Update localized UI elements at runtime
function Update-LocalizedUI {
    param()
    try {
        $lang = $sync.preferences.language
        if ($sync.ThemeButton) { $sync.ThemeButton.ToolTip = Get-LocalizedString -Key 'ThemeButtonTooltip' -Language $lang }
        if ($sync.AutoThemeMenuItem) { $sync.AutoThemeMenuItem.Header = Get-LocalizedString -Key 'Auto' -Language $lang; $sync.AutoThemeMenuItem.ToolTip = Get-LocalizedString -Key 'AutoTooltip' -Language $lang }
        if ($sync.DarkThemeMenuItem) { $sync.DarkThemeMenuItem.Header = Get-LocalizedString -Key 'Dark' -Language $lang; $sync.DarkThemeMenuItem.ToolTip = Get-LocalizedString -Key 'DarkTooltip' -Language $lang }
        if ($sync.LightThemeMenuItem) { $sync.LightThemeMenuItem.Header = Get-LocalizedString -Key 'Light' -Language $lang; $sync.LightThemeMenuItem.ToolTip = Get-LocalizedString -Key 'LightTooltip' -Language $lang }
        if ($sync.FontScalingButton) { $sync.FontScalingButton.ToolTip = Get-LocalizedString -Key 'FontScalingTooltip' -Language $lang }
        if ($sync.SearchBar) { $sync.SearchBar.ToolTip = Get-LocalizedString -Key 'SearchTooltip' -Language $lang }
        if ($sync.WPFWin11ISODownloadLink) { $sync.WPFWin11ISODownloadLink.Content = Get-LocalizedString -Key 'OpenMicrosoftDownloadPage' -Language $lang }
        if ($sync.WPFUpdatesdefault) { $sync.WPFUpdatesdefault.Content = Get-LocalizedString -Key 'DefaultSettings' -Language $lang }
        if ($sync.WPFUpdatessecurity) { $sync.WPFUpdatessecurity.Content = Get-LocalizedString -Key 'SecuritySettings' -Language $lang }
        if ($sync.LanguageLabelTextBlock) { $sync.LanguageLabelTextBlock.Text = Get-LocalizedString -Key 'LanguageLabel' -Language $lang }
        if ($sync.WPFOfflineBannerTextBlock) { $sync.WPFOfflineBannerTextBlock.Text = Get-LocalizedString -Key 'OfflineModeNoInternet' -Language $lang }
        if ($sync.AboutMenuItem) { $sync.AboutMenuItem.Header = Get-LocalizedString -Key 'About' -Language $lang }
        if ($sync.DocumentationMenuItem) { $sync.DocumentationMenuItem.Header = Get-LocalizedString -Key 'Documentation' -Language $lang }
        if ($sync.SponsorMenuItem) { $sync.SponsorMenuItem.Header = Get-LocalizedString -Key 'Sponsors' -Language $lang }
        if ($sync.ImportMenuItem) { $sync.ImportMenuItem.Header = Get-LocalizedString -Key 'Import' -Language $lang; $sync.ImportMenuItem.ToolTip = Get-LocalizedString -Key 'ImportTooltip' -Language $lang }
        if ($sync.ExportMenuItem) { $sync.ExportMenuItem.Header = Get-LocalizedString -Key 'Export' -Language $lang; $sync.ExportMenuItem.ToolTip = Get-LocalizedString -Key 'ExportTooltip' -Language $lang }

        if ($sync.WPFTab1) { $sync.WPFTab1.Header = Get-LocalizedString -Key 'InstallTab' -Language $lang }
        if ($sync.WPFTab2) { $sync.WPFTab2.Header = Get-LocalizedString -Key 'TweaksTab' -Language $lang }
        if ($sync.WPFTab3) { $sync.WPFTab3.Header = Get-LocalizedString -Key 'ConfigTab' -Language $lang }
        if ($sync.WPFTab4) { $sync.WPFTab4.Header = Get-LocalizedString -Key 'UpdatesTab' -Language $lang }
        if ($sync.WPFTab5) { $sync.WPFTab5.Header = Get-LocalizedString -Key 'Win11ISOTab' -Language $lang }

        Set-LocalizedControlValue -Control $sync.WPFTab1BTTextBlock -Property Text -Key 'InstallTab' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFTab2BTTextBlock -Property Text -Key 'TweaksTab' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFTab3BTTextBlock -Property Text -Key 'ConfigTab' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFTab4BTTextBlock -Property Text -Key 'UpdatesTab' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFTab5BTTextBlock -Property Text -Key 'Win11CreatorTab' -Language $lang

        Set-LocalizedControlValue -Control $sync.FontScalingTitleTextBlock -Property Text -Key 'FontScalingTitle' -Language $lang
        Set-LocalizedControlValue -Control $sync.FontScalingSmallTextBlock -Property Text -Key 'Small' -Language $lang
        Set-LocalizedControlValue -Control $sync.FontScalingLargeTextBlock -Property Text -Key 'Large' -Language $lang
        Set-LocalizedControlValue -Control $sync.FontScalingResetButton -Property Content -Key 'Reset' -Language $lang
        Set-LocalizedControlValue -Control $sync.FontScalingApplyButton -Property Content -Key 'Apply' -Language $lang

        Set-LocalizedControlValue -Control $sync.WPFTweaksRecommendedLabel -Property Content -Key 'RecommendedSelections' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFstandard -Property Content -Key 'Standard' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFminimal -Property Content -Key 'Minimal' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFClearTweaksSelection -Property Content -Key 'Clear' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFGetInstalledTweaks -Property Content -Key 'GetInstalledTweaks' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFTweaksInfoTextBlock -Property Text -Key 'TweaksNote' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFTweaksbutton -Property Content -Key 'RunTweaks' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFUndoall -Property Content -Key 'UndoSelectedTweaks' -Language $lang

        Set-LocalizedControlValue -Control $sync.WPFUpdatesDefaultDescriptionTextBlock -Property Text -Key 'DefaultUpdateDescription' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFUpdatesSecurityDescriptionTextBlock -Property Text -Key 'SecurityUpdateDescription' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFUpdatesdisable -Property Content -Key 'DisableAllUpdates' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFUpdatesDisableDescriptionTextBlock -Property Text -Key 'DisableUpdateDescription' -Language $lang

        Set-LocalizedControlValue -Control $sync.WPFWin11ISOStep1TitleTextBlock -Property Text -Key 'Step1SelectWindows11ISO' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOStep1DescriptionTextBlock -Property Text -Key 'Step1SelectWindows11ISODescription' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOStep1NoteTextBlock -Property Text -Key 'Step1SelectWindows11ISONote' -Language $lang
        if ($sync.WPFWin11ISOPath) {
            $defaultIsoPathTexts = @(
                'No ISO selected...',
                (Get-LocalizedString -Key 'NoISOSelected' -Language 'en'),
                (Get-LocalizedString -Key 'NoISOSelected' -Language 'es')
            ) | Select-Object -Unique

            if ($defaultIsoPathTexts -contains $sync.WPFWin11ISOPath.Text) {
                Set-LocalizedControlValue -Control $sync.WPFWin11ISOPath -Property Text -Key 'NoISOSelected' -Language $lang
            }
        }
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOBrowseButton -Property Content -Key 'Browse' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOWarningTitleTextBlock -Property Text -Key 'OfficialISOWarningTitle' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOWarningDescriptionTextBlock -Property Text -Key 'OfficialISOWarningDescription' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOWarningChooseTextBlock -Property Text -Key 'MicrosoftDownloadChoose' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOWarningOptionsTextBlock -Property Text -Key 'MicrosoftDownloadOptions' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOStep2TitleTextBlock -Property Text -Key 'Step2MountVerifyISO' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOStep2DescriptionTextBlock -Property Text -Key 'Step2MountVerifyISODescription' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOMountButton -Property Content -Key 'MountVerifyISO' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOInjectDrivers -Property Content -Key 'InjectCurrentSystemDrivers' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOInjectDrivers -Property ToolTip -Key 'InjectCurrentSystemDriversTooltip' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOEditionLabelTextBlock -Property Text -Key 'SelectEdition' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOStep3TitleTextBlock -Property Text -Key 'Step3ModifyInstallWim' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOStep3DescriptionTextBlock -Property Text -Key 'Step3ModifyInstallWimDescription' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOModifyButton -Property Content -Key 'RunWindowsISOModificationAndCreator' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOStep4TitleTextBlock -Property Text -Key 'Step4OutputTitle' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOCleanResetButton -Property Content -Key 'CleanReset' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOCleanResetButton -Property ToolTip -Key 'CleanResetTooltip' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOChooseISOButton -Property Content -Key 'SaveAsISOFile' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOChooseUSBButton -Property Content -Key 'WriteDirectlyToUSBDrive' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOUSBWarningTextBlock -Property Text -Key 'USBWarning' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISORefreshUSBButton -Property Content -Key 'Refresh' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOWriteUSBButton -Property Content -Key 'EraseWriteToUSB' -Language $lang
        Set-LocalizedControlValue -Control $sync.WPFWin11ISOStatusLogTitleTextBlock -Property Text -Key 'StatusLog' -Language $lang
        if ($sync.WPFWin11ISOStatusLog) {
            $defaultStatusTexts = @(
                'Ready. Please select a Windows 11 ISO to begin.',
                (Get-LocalizedString -Key 'ReadyPleaseSelectISO' -Language 'en'),
                (Get-LocalizedString -Key 'ReadyPleaseSelectISO' -Language 'es')
            ) | Select-Object -Unique

            if ($defaultStatusTexts -contains $sync.WPFWin11ISOStatusLog.Text) {
                Set-LocalizedControlValue -Control $sync.WPFWin11ISOStatusLog -Property Text -Key 'ReadyPleaseSelectISO' -Language $lang
            }
        }

        # Initialize language combobox selection
        if ($sync.LanguageComboBox) {
            foreach ($item in $sync.LanguageComboBox.Items) {
                if ($item.Tag) {
                    switch ($item.Tag.ToString().Substring(0,2).ToLower()) {
                        'en' { $item.Content = Get-LocalizedString -Key 'English' -Language $lang }
                        'es' { $item.Content = Get-LocalizedString -Key 'Spanish' -Language $lang }
                    }
                }
            }

            $code = $sync.preferences.language
            for ($i=0; $i -lt $sync.LanguageComboBox.Items.Count; $i++) {
                $item = $sync.LanguageComboBox.Items[$i]
                if ($item.Tag -and $item.Tag.ToString().Substring(0,2).ToLower() -eq $code) {
                    $sync.LanguageComboBox.SelectedIndex = $i; break
                }
            }
        }
    } catch {
        Write-Debug "Update-LocalizedUI failed: $_"
    }
}

# Wire language selection change to save preferences and refresh UI
if ($null -ne $sync.LanguageComboBox) {
    $sync.LanguageComboBox.Add_SelectionChanged({
        param($sender, $eventArgs)
        try {
            $sel = $sender.SelectedItem
            if ($sel -and $sel.Tag) {
                $sync.preferences.language = $sel.Tag.ToString().Substring(0,2).ToLower()
                Set-Preferences -save
                Refresh-InstallTabUI
                Refresh-PreferencePanelsUI
                Update-LocalizedUI
            }
        } catch {
            Write-Debug "Language selection handler failed: $_"
        }
    })
}

# Run initial localized UI update
Update-LocalizedUI
Bind-SharedControlEvents

#===========================================================================
# Setup background config
#===========================================================================

# Load computer information in the background
Invoke-WPFRunspace -ScriptBlock {
    try {
        $ProgressPreference = "SilentlyContinue"
        $sync.ConfigLoaded = $False
        $sync.ComputerInfo = Get-ComputerInfo
        $sync.ConfigLoaded = $True
    }
    finally{
        $ProgressPreference = $oldProgressPreference
    }

} | Out-Null

#===========================================================================
# Setup and Show the Form
#===========================================================================

# Print the logo
Show-CTTLogo

# Progress bar in taskbaritem > Set-WinUtilProgressbar
$sync["Form"].TaskbarItemInfo = New-Object System.Windows.Shell.TaskbarItemInfo
Set-WinUtilTaskbaritem -state "None"

# Set the titlebar
$sync["Form"].title = $sync["Form"].title + " " + $sync.version
# Set the commands that will run when the form is closed
$sync["Form"].Add_Closing({
    $sync.runspace.Dispose()
    $sync.runspace.Close()
    [System.GC]::Collect()
})

# Attach the event handler to the Click event
$sync.SearchBarClearButton.Add_Click({
    $sync.SearchBar.Text = ""
    $sync.SearchBarClearButton.Visibility = "Collapsed"

    # Focus the search bar after clearing the text
    $sync.SearchBar.Focus()
    $sync.SearchBar.SelectAll()
})

# add some shortcuts for people that don't like clicking
$commonKeyEvents = {
    # Prevent shortcuts from executing if a process is already running
    if ($sync.ProcessRunning -eq $true) {
        return
    }

    # Handle key presses of single keys
    switch ($_.Key) {
        "Escape" { $sync.SearchBar.Text = "" }
    }
    # Handle Alt key combinations for navigation
    if ($_.KeyboardDevice.Modifiers -eq "Alt") {
        $keyEventArgs = $_
        switch ($_.SystemKey) {
            "I" { Invoke-WPFButton "WPFTab1BT"; $keyEventArgs.Handled = $true } # Navigate to Install tab and suppress Windows Warning Sound
            "T" { Invoke-WPFButton "WPFTab2BT"; $keyEventArgs.Handled = $true } # Navigate to Tweaks tab
            "C" { Invoke-WPFButton "WPFTab3BT"; $keyEventArgs.Handled = $true } # Navigate to Config tab
            "U" { Invoke-WPFButton "WPFTab4BT"; $keyEventArgs.Handled = $true } # Navigate to Updates tab
            "W" { Invoke-WPFButton "WPFTab5BT"; $keyEventArgs.Handled = $true } # Navigate to Win11ISO tab
        }
    }
    # Handle Ctrl key combinations for specific actions
    if ($_.KeyboardDevice.Modifiers -eq "Ctrl") {
        switch ($_.Key) {
            "F" { $sync.SearchBar.Focus() } # Focus on the search bar
            "Q" { $this.Close() } # Close the application
        }
    }
}
$sync["Form"].Add_PreViewKeyDown($commonKeyEvents)

$sync["Form"].Add_MouseLeftButtonDown({
    Invoke-WPFPopup -Action "Hide" -Popups @("Settings", "Theme", "FontScaling")
    $sync["Form"].DragMove()
})

$sync["Form"].Add_MouseDoubleClick({
    if ($_.OriginalSource.Name -eq "NavDockPanel" -or
        $_.OriginalSource.Name -eq "GridBesideNavDockPanel") {
            if ($sync["Form"].WindowState -eq [Windows.WindowState]::Normal) {
                $sync["Form"].WindowState = [Windows.WindowState]::Maximized
            }
            else{
                $sync["Form"].WindowState = [Windows.WindowState]::Normal
            }
    }
})

$sync["Form"].Add_Deactivated({
    Write-Debug "WinUtil lost focus"
    Invoke-WPFPopup -Action "Hide" -Popups @("Settings", "Theme", "FontScaling")
})

$sync["Form"].Add_ContentRendered({
    # Load the Windows Forms assembly
    Add-Type -AssemblyName System.Windows.Forms
    $primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
    # Check if the primary screen is found
    if ($primaryScreen) {
        # Extract screen width and height for the primary monitor
        $screenWidth = $primaryScreen.Bounds.Width
        $screenHeight = $primaryScreen.Bounds.Height

        # Print the screen size
        Write-Debug "Primary Monitor Width: $screenWidth pixels"
        Write-Debug "Primary Monitor Height: $screenHeight pixels"

        # Compare with the primary monitor size
        if ($sync.Form.ActualWidth -gt $screenWidth -or $sync.Form.ActualHeight -gt $screenHeight) {
            Write-Debug "The specified width and/or height is greater than the primary monitor size."
            $sync.Form.Left = 0
            $sync.Form.Top = 0
            $sync.Form.Width = $screenWidth
            $sync.Form.Height = $screenHeight
        } else {
            Write-Debug "The specified width and height are within the primary monitor size limits."
        }
    } else {
        Write-Debug "Unable to retrieve information about the primary monitor."
    }

    if ($PARAM_OFFLINE) {
        # Show offline banner
        $sync.WPFOfflineBanner.Visibility = [System.Windows.Visibility]::Visible

        # Disable the install tab
        $sync.WPFTab1BT.IsEnabled = $false
        $sync.WPFTab1BT.Opacity = 0.5
        $sync.WPFTab1BT.ToolTip = "Internet connection required for installing applications"

        # Disable install-related buttons
        $sync.WPFInstall.IsEnabled = $false
        $sync.WPFUninstall.IsEnabled = $false
        $sync.WPFInstallUpgrade.IsEnabled = $false
        $sync.WPFGetInstalled.IsEnabled = $false

        # Show offline indicator
        Write-Host "Offline mode detected - Install tab disabled" -ForegroundColor Yellow

        # Optionally switch to a different tab if install tab was going to be default
        Invoke-WPFTab "WPFTab2BT"  # Switch to Tweaks tab instead
    }
    else {
        # Online - ensure install tab is enabled
        $sync.WPFTab1BT.IsEnabled = $true
        $sync.WPFTab1BT.Opacity = 1.0
        $sync.WPFTab1BT.ToolTip = $null
        Invoke-WPFTab "WPFTab1BT"  # Default to install tab
    }

    $sync["Form"].Focus()

   if ($PARAM_CONFIG -and -not [string]::IsNullOrWhiteSpace($PARAM_CONFIG)) {
        Write-Host "Running config file tasks..."
        Invoke-WPFImpex -type "import" -Config $PARAM_CONFIG
        if ($PARAM_RUN) {
            Invoke-WinUtilAutoRun
        }
    }

})

# The SearchBarTimer is used to delay the search operation until the user has stopped typing for a short period
# This prevents the ui from stuttering when the user types quickly as it dosnt need to update the ui for every keystroke

$searchBarTimer = New-Object System.Windows.Threading.DispatcherTimer
$searchBarTimer.Interval = [TimeSpan]::FromMilliseconds(300)
$searchBarTimer.IsEnabled = $false

$searchBarTimer.add_Tick({
    $searchBarTimer.Stop()
    switch ($sync.currentTab) {
        "Install" {
            Find-AppsByNameOrDescription -SearchString $sync.SearchBar.Text
        }
        "Tweaks" {
            Find-TweaksByNameOrDescription -SearchString $sync.SearchBar.Text
        }
    }
})
$sync["SearchBar"].Add_TextChanged({
    if ($sync.SearchBar.Text -ne "") {
        $sync.SearchBarClearButton.Visibility = "Visible"
    } else {
        $sync.SearchBarClearButton.Visibility = "Collapsed"
    }
    if ($searchBarTimer.IsEnabled) {
        $searchBarTimer.Stop()
    }
    $searchBarTimer.Start()
})

$sync["Form"].Add_Loaded({
    param($e)
    $sync.Form.MinWidth = "1000"
    $sync["Form"].MaxWidth = [Double]::PositiveInfinity
    $sync["Form"].MaxHeight = [Double]::PositiveInfinity
})

$NavLogoPanel = $sync["Form"].FindName("NavLogoPanel")
$NavLogoPanel.Children.Add((Invoke-WinUtilAssets -Type "logo" -Size 25)) | Out-Null


if (Test-Path "$winutildir\logo.ico") {
    $sync["logorender"] = "$winutildir\logo.ico"
} else {
    $sync["logorender"] = (Invoke-WinUtilAssets -Type "Logo" -Size 90 -Render)
}
$sync["checkmarkrender"] = (Invoke-WinUtilAssets -Type "checkmark" -Size 512 -Render)
$sync["warningrender"] = (Invoke-WinUtilAssets -Type "warning" -Size 512 -Render)

Set-WinUtilTaskbaritem -overlay "logo"

$sync["Form"].Add_Activated({
    Set-WinUtilTaskbaritem -overlay "logo"
})

$sync["ThemeButton"].Add_Click({
    Write-Debug "ThemeButton clicked"
    Invoke-WPFPopup -PopupActionTable @{ "Settings" = "Hide"; "Theme" = "Toggle"; "FontScaling" = "Hide" }
})
$sync["AutoThemeMenuItem"].Add_Click({
    Write-Debug "About clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Theme")
    Invoke-WinutilThemeChange -theme "Auto"
})
$sync["DarkThemeMenuItem"].Add_Click({
    Write-Debug "Dark Theme clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Theme")
    Invoke-WinutilThemeChange -theme "Dark"
})
$sync["LightThemeMenuItem"].Add_Click({
    Write-Debug "Light Theme clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Theme")
    Invoke-WinutilThemeChange -theme "Light"
})

$sync["SettingsButton"].Add_Click({
    Write-Debug "SettingsButton clicked"
    Invoke-WPFPopup -PopupActionTable @{ "Settings" = "Toggle"; "Theme" = "Hide"; "FontScaling" = "Hide" }
})
$sync["ImportMenuItem"].Add_Click({
    Write-Debug "Import clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Settings")
    Invoke-WPFImpex -type "import"
})
$sync["ExportMenuItem"].Add_Click({
    Write-Debug "Export clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Settings")
    Invoke-WPFImpex -type "export"
})
$sync["AboutMenuItem"].Add_Click({
    Write-Debug "About clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Settings")

    $authorInfo = @"
Author   : <a href="https://github.com/ChrisTitusTech">@ChrisTitusTech</a>
UI       : <a href="https://github.com/MyDrift-user">@MyDrift-user</a>, <a href="https://github.com/Marterich">@Marterich</a>
Runspace : <a href="https://github.com/DeveloperDurp">@DeveloperDurp</a>, <a href="https://github.com/Marterich">@Marterich</a>
GitHub   : <a href="https://github.com/ChrisTitusTech/winutil">ChrisTitusTech/winutil</a>
Version  : <a href="https://github.com/ChrisTitusTech/winutil/releases/tag/$($sync.version)">$($sync.version)</a>
"@
    Show-CustomDialog -Title "About" -Message $authorInfo
})
$sync["DocumentationMenuItem"].Add_Click({
    Write-Debug "Documentation clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Settings")
    Start-Process "https://winutil.christitus.com/"
})
$sync["SponsorMenuItem"].Add_Click({
    Write-Debug "Sponsors clicked"
    Invoke-WPFPopup -Action "Hide" -Popups @("Settings")

    $authorInfo = @"
<a href="https://github.com/sponsors/ChrisTitusTech">Current sponsors for ChrisTitusTech:</a>
"@
    $authorInfo += "`n"
    try {
        $sponsors = Invoke-WinUtilSponsors
        foreach ($sponsor in $sponsors) {
            $authorInfo += "<a href=`"https://github.com/sponsors/ChrisTitusTech`">$sponsor</a>`n"
        }
    } catch {
        $authorInfo += "An error occurred while fetching or processing the sponsors: $_`n"
    }
    Show-CustomDialog -Title "Sponsors" -Message $authorInfo -EnableScroll $true
})

# Font Scaling Event Handlers
$sync["FontScalingButton"].Add_Click({
    Write-Debug "FontScalingButton clicked"
    Invoke-WPFPopup -PopupActionTable @{ "Settings" = "Hide"; "Theme" = "Hide"; "FontScaling" = "Toggle" }
})

$sync["FontScalingSlider"].Add_ValueChanged({
    param($slider)
    $percentage = [math]::Round($slider.Value * 100)
    $sync.FontScalingValue.Text = "$percentage%"
})

$sync["FontScalingResetButton"].Add_Click({
    Write-Debug "FontScalingResetButton clicked"
    $sync.FontScalingSlider.Value = 1.0
    $sync.FontScalingValue.Text = "100%"
})

$sync["FontScalingApplyButton"].Add_Click({
    Write-Debug "FontScalingApplyButton clicked"
    $scaleFactor = $sync.FontScalingSlider.Value
    Invoke-WinUtilFontScaling -ScaleFactor $scaleFactor
    Invoke-WPFPopup -Action "Hide" -Popups @("FontScaling")
})

# ── Win11ISO Tab button handlers ──────────────────────────────────────────────

$sync["WPFTab5BT"].Add_Click({
    $sync["Form"].Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background, [action]{ Invoke-WinUtilISOCheckExistingWork }) | Out-Null
})

$sync["WPFWin11ISOBrowseButton"].Add_Click({
    Write-Debug "WPFWin11ISOBrowseButton clicked"
    Invoke-WinUtilISOBrowse
})

$sync["WPFWin11ISODownloadLink"].Add_Click({
    Write-Debug "WPFWin11ISODownloadLink clicked"
    Start-Process "https://www.microsoft.com/software-download/windows11"
})

$sync["WPFWin11ISOMountButton"].Add_Click({
    Write-Debug "WPFWin11ISOMountButton clicked"
    Invoke-WinUtilISOMountAndVerify
})

$sync["WPFWin11ISOModifyButton"].Add_Click({
    Write-Debug "WPFWin11ISOModifyButton clicked"
    Invoke-WinUtilISOModify
})

$sync["WPFWin11ISOChooseISOButton"].Add_Click({
    Write-Debug "WPFWin11ISOChooseISOButton clicked"
    $sync["WPFWin11ISOOptionUSB"].Visibility = "Collapsed"
    Invoke-WinUtilISOExport
})

$sync["WPFWin11ISOChooseUSBButton"].Add_Click({
    Write-Debug "WPFWin11ISOChooseUSBButton clicked"
    $sync["WPFWin11ISOOptionUSB"].Visibility = "Visible"
    Invoke-WinUtilISORefreshUSBDrives
})

$sync["WPFWin11ISORefreshUSBButton"].Add_Click({
    Write-Debug "WPFWin11ISORefreshUSBButton clicked"
    Invoke-WinUtilISORefreshUSBDrives
})

$sync["WPFWin11ISOWriteUSBButton"].Add_Click({
    Write-Debug "WPFWin11ISOWriteUSBButton clicked"
    Invoke-WinUtilISOWriteUSB
})

$sync["WPFWin11ISOCleanResetButton"].Add_Click({
    Write-Debug "WPFWin11ISOCleanResetButton clicked"
    Invoke-WinUtilISOCleanAndReset
})

# ──────────────────────────────────────────────────────────────────────────────

$sync["Form"].ShowDialog() | out-null
Stop-Transcript
