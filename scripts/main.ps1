# SPDX-License-Identifier: MIT
# Set the maximum number of threads for the RunspacePool to the number of threads on the machine
$maxthreads = [int]$env:NUMBER_OF_PROCESSORS

# Create a new session state for parsing variables into our runspace
$hashVars = New-object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'sync',$sync,$Null
$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

# Add the variable to the session state
$InitialSessionState.Variables.Add($hashVars)

# Get every private function and add them to the session state
$functions = (Get-ChildItem function:\).where{$_.name -like "*winutil*" -or $_.name -like "*WPF*"}
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


$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'

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

Invoke-WinutilThemeChange -init $true
# Load the configuration files
#Invoke-WPFUIElements -configVariable $sync.configs.nav -targetGridName "WPFMainGrid"
Invoke-WPFUIElements -configVariable $sync.configs.applications -targetGridName "appspanel" -columncount 5
Invoke-WPFUIElements -configVariable $sync.configs.tweaks -targetGridName "tweakspanel" -columncount 2
Invoke-WPFUIElements -configVariable $sync.configs.feature -targetGridName "featurespanel" -columncount 2

#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {$sync["$("$($psitem.Name)")"] = $sync["Form"].FindName($psitem.Name)}

#Persist the Chocolatey preference across winutil restarts
$ChocoPreferencePath = "$env:LOCALAPPDATA\winutil\preferChocolatey.ini"
$sync.WPFpreferChocolatey.Add_Checked({New-Item -Path $ChocoPreferencePath -Force })
$sync.WPFpreferChocolatey.Add_Unchecked({Remove-Item $ChocoPreferencePath -Force})
if (Test-Path $ChocoPreferencePath) {
    $sync.WPFpreferChocolatey.IsChecked = $true
}

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

#===========================================================================
# Setup background config
#===========================================================================

# Load computer information in the background
Invoke-WPFRunspace -ScriptBlock {
    try {
        $oldProgressPreference = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"
        $sync.ConfigLoaded = $False
        $sync.ComputerInfo = Get-ComputerInfo
        $sync.ConfigLoaded = $True
    }
    finally{
        $ProgressPreference = "Continue"
    }

} | Out-Null

#===========================================================================
# Setup and Show the Form
#===========================================================================

# Print the logo
Invoke-WPFFormVariables

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
})

# add some shortcuts for people that don't like clicking
$commonKeyEvents = {
    if ($sync.ProcessRunning -eq $true) {
        return
    }

    if ($_.Key -eq "Escape") {
        $sync.SearchBar.SelectAll()
        $sync.SearchBar.Text = ""
        $sync.SearchBarClearButton.Visibility = "Collapsed"
        return
    }

    # don't ask, I know what I'm doing, just go...
    if (($_.Key -eq "Q" -and $_.KeyboardDevice.Modifiers -eq "Ctrl")) {
        $this.Close()
    }
    if ($_.KeyboardDevice.Modifiers -eq "Alt") {
        if ($_.SystemKey -eq "I") {
            Invoke-WPFButton "WPFTab1BT"
        }
        if ($_.SystemKey -eq "T") {
            Invoke-WPFButton "WPFTab2BT"
        }
        if ($_.SystemKey -eq "C") {
            Invoke-WPFButton "WPFTab3BT"
        }
        if ($_.SystemKey -eq "U") {
            Invoke-WPFButton "WPFTab4BT"
        }
        if ($_.SystemKey -eq "M") {
            Invoke-WPFButton "WPFTab5BT"
        }
        if ($_.SystemKey -eq "P") {
            Write-Host "Your Windows Product Key: $((Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey)"
        }
    }
    # shortcut for the filter box
    if ($_.Key -eq "F" -and $_.KeyboardDevice.Modifiers -eq "Ctrl") {
        if ($sync.SearchBar.Text -eq "Ctrl-F to filter") {
            $sync.SearchBar.SelectAll()
            $sync.SearchBar.Text = ""
        }
        $sync.SearchBar.Focus()
    }
}

$sync["Form"].Add_PreViewKeyDown($commonKeyEvents)

$sync["Form"].Add_MouseLeftButtonDown({
    # Hide Settings and Theme Popup on click anywhere else
    if ($sync.SettingsButton.IsOpen -or
        $sync.ThemePopup.IsOpen) {
            $sync.SettingsPopup.IsOpen = $false
            $sync.ThemePopup.IsOpen = $false
        }
    $sync["Form"].DragMove()
})

$sync["Form"].Add_MouseDoubleClick({
    if ($_.OriginalSource -is [System.Windows.Controls.Grid] -or
        $_.OriginalSource -is [System.Windows.Controls.StackPanel]) {
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
    # Hide Settings and Theme Popup on Winutil Focus Loss
    if ($sync.SettingsButton.IsOpen -or
        $sync.ThemePopup.IsOpen) {
            $sync.SettingsPopup.IsOpen = $false
            $sync.ThemePopup.IsOpen = $false
    }
})

$sync["Form"].Add_ContentRendered({

    try {
        [void][Window]
    } catch {
Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        public class Window {
            [DllImport("user32.dll")]
            public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);

            [DllImport("user32.dll")]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

            [DllImport("user32.dll")]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw);

            [DllImport("user32.dll")]
            public static extern int GetSystemMetrics(int nIndex);
        };
        public struct RECT {
            public int Left;   // x position of upper-left corner
            public int Top;    // y position of upper-left corner
            public int Right;  // x position of lower-right corner
            public int Bottom; // y position of lower-right corner
        }
"@
    }

   foreach ($proc in (Get-Process).where{ $_.MainWindowTitle -and $_.MainWindowTitle -like "*titus*" }) {
        # Check if the process's MainWindowHandle is valid
        if ($proc.MainWindowHandle -ne [System.IntPtr]::Zero) {
            Write-Debug "MainWindowHandle: $($proc.Id) $($proc.MainWindowTitle) $($proc.MainWindowHandle)"
            $windowHandle = $proc.MainWindowHandle
        } else {
            Write-Warning "Process found, but no MainWindowHandle: $($proc.Id) $($proc.MainWindowTitle)"

        }
    }

    $rect = New-Object RECT
    [Window]::GetWindowRect($windowHandle, [ref]$rect)
    $width  = $rect.Right  - $rect.Left
    $height = $rect.Bottom - $rect.Top

    Write-Debug "UpperLeft:$($rect.Left),$($rect.Top) LowerBottom:$($rect.Right),$($rect.Bottom). Width:$($width) Height:$($height)"

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
        if ($width -gt $screenWidth -or $height -gt $screenHeight) {
            Write-Debug "The specified width and/or height is greater than the primary monitor size."
            [void][Window]::MoveWindow($windowHandle, 0, 0, $screenWidth, $screenHeight, $True)
        } else {
            Write-Debug "The specified width and height are within the primary monitor size limits."
        }
    } else {
        Write-Debug "Unable to retrieve information about the primary monitor."
    }

    Invoke-WPFTab "WPFTab1BT"
    $sync["Form"].Focus()

    # maybe this is not the best place to load and execute config file?
    # maybe community can help?
    if ($PARAM_CONFIG) {
        Invoke-WPFImpex -type "import" -Config $PARAM_CONFIG
        if ($PARAM_RUN) {
            while ($sync.ProcessRunning) {
                Start-Sleep -Seconds 5
            }
            Start-Sleep -Seconds 5

            Write-Host "Applying tweaks..."
            Invoke-WPFtweaksbutton
            while ($sync.ProcessRunning) {
                Start-Sleep -Seconds 5
            }
            Start-Sleep -Seconds 5

            Write-Host "Installing features..."
            Invoke-WPFFeatureInstall
            while ($sync.ProcessRunning) {
                Start-Sleep -Seconds 5
            }

            Start-Sleep -Seconds 5
            Write-Host "Installing applications..."
            while ($sync.ProcessRunning) {
                Start-Sleep -Seconds 1
            }
            Invoke-WPFInstall
            Start-Sleep -Seconds 5

            Write-Host "Done."
        }
    }

})

# Add event handlers for the RadioButtons
$sync["ISOdownloader"].add_Checked({
    $sync["ISORelease"].Visibility = [System.Windows.Visibility]::Visible
    $sync["ISOLanguage"].Visibility = [System.Windows.Visibility]::Visible
})

$sync["ISOmanual"].add_Checked({
    $sync["ISORelease"].Visibility = [System.Windows.Visibility]::Collapsed
    $sync["ISOLanguage"].Visibility = [System.Windows.Visibility]::Collapsed
})

$sync["ISORelease"].Items.Add("23H2") | Out-Null
$sync["ISORelease"].Items.Add("22H2") | Out-Null
$sync["ISORelease"].Items.Add("21H2") | Out-Null
$sync["ISORelease"].SelectedItem = "23H2"

$currentCulture = Get-FidoLangFromCulture -langName (Get-Culture).Name

$sync["ISOLanguage"].Items.Add($currentCulture) | Out-Null
if ($currentCulture -ne "English International") {
    $sync["ISOLanguage"].Items.Add("English International") | Out-Null
}
if ($currentCulture -ne "English") {
    $sync["ISOLanguage"].Items.Add("English") | Out-Null
}
if ($sync["ISOLanguage"].Items.Count -eq 1) {
    $sync["ISOLanguage"].IsEnabled = $false
}
$sync["ISOLanguage"].SelectedItem = $currentCulture


# Load Checkboxes and Labels outside of the Filter function only once on startup for performance reasons
$filter = Get-WinUtilVariables -Type CheckBox
$CheckBoxes = ($sync.GetEnumerator()).where{ $psitem.Key -in $filter }

$filter = Get-WinUtilVariables -Type Label
$labels = @{}
($sync.GetEnumerator()).where{$PSItem.Key -in $filter} | ForEach-Object {$labels[$_.Key] = $_.Value}

$allCategories = $checkBoxes.Name | ForEach-Object {$sync.configs.applications.$_} | Select-Object  -Unique -ExpandProperty category

$sync["SearchBar"].Add_TextChanged({
    if ($sync.SearchBar.Text -ne "") {
        $sync.SearchBarClearButton.Visibility = "Visible"
    } else {
        $sync.SearchBarClearButton.Visibility = "Collapsed"
    }

    $activeApplications = @()

    $textToSearch = $sync.SearchBar.Text.ToLower()

    foreach ($CheckBox in $CheckBoxes) {
        # Skip if the checkbox is null, it doesn't have content or it is the prefer Choco checkbox
        if ($CheckBox -eq $null -or $CheckBox.Value -eq $null -or $CheckBox.Value.Content -eq $null -or $CheckBox.Name -eq "WPFpreferChocolatey") {
            continue
        }

        $checkBoxName = $CheckBox.Key
        $textBlockName = $checkBoxName + "Link"

        # Retrieve the corresponding text block based on the generated name
        $textBlock = $sync[$textBlockName]

        if ($CheckBox.Value.Content.ToString().ToLower().Contains($textToSearch)) {
            $CheckBox.Value.Visibility = "Visible"
            $activeApplications += $sync.configs.applications.$checkboxName
            # Set the corresponding text block visibility
            if ($textBlock -ne $null -and $textBlock -is [System.Windows.Controls.TextBlock]) {
                $textBlock.Visibility = "Visible"
            }
        } else {
            $CheckBox.Value.Visibility = "Collapsed"
            # Set the corresponding text block visibility
            if ($textBlock -ne $null -and $textBlock -is [System.Windows.Controls.TextBlock]) {
                $textBlock.Visibility = "Collapsed"
            }
        }
    }

    $activeCategories = $activeApplications | Select-Object -ExpandProperty category -Unique

    foreach ($category in $activeCategories) {
        $sync[$category].Visibility = "Visible"
    }
    if ($activeCategories) {
        $inactiveCategories = Compare-Object -ReferenceObject $allCategories -DifferenceObject $activeCategories -PassThru
    } else {
        $inactiveCategories = $allCategories
    }
    foreach ($category in $inactiveCategories) {
        $sync[$category].Visibility = "Collapsed"
    }
})

$sync["Form"].Add_Loaded({
    param($e)
    $sync["Form"].MaxWidth = [Double]::PositiveInfinity
    $sync["Form"].MaxHeight = [Double]::PositiveInfinity
})

$NavLogoPanel = $sync["Form"].FindName("NavLogoPanel")
$NavLogoPanel.Children.Add((Invoke-WinUtilAssets -Type "logo" -Size 25)) | Out-Null

# Initialize the hashtable
$winutildir = @{}

# Set the path for the winutil directory
$winutildir["path"] = "$env:LOCALAPPDATA\winutil\"
[System.IO.Directory]::CreateDirectory($winutildir["path"]) | Out-Null

$winutildir["logo.ico"] = $winutildir["path"] + "cttlogo.ico"

if (Test-Path $winutildir["logo.ico"]) {
    $sync["logorender"] = $winutildir["logo.ico"]
} else {
    $sync["logorender"] = (Invoke-WinUtilAssets -Type "Logo" -Size 90 -Render)
}
$sync["checkmarkrender"] = (Invoke-WinUtilAssets -Type "checkmark" -Size 512 -Render)
$sync["warningrender"] = (Invoke-WinUtilAssets -Type "warning" -Size 512 -Render)

Set-WinUtilTaskbaritem -overlay "logo"

$sync["Form"].Add_Activated({
    Set-WinUtilTaskbaritem -overlay "logo"
})
# Define event handler for ThemeButton click
$sync["ThemeButton"].Add_Click({
    if ($sync.ThemePopup.IsOpen) {
        $sync.ThemePopup.IsOpen = $false
    }
    else{
        $sync.ThemePopup.IsOpen = $true
    }
    $sync.SettingsPopup.IsOpen = $false
})

# Define event handlers for menu items
$sync["AutoThemeMenuItem"].Add_Click({
    $sync.ThemePopup.IsOpen = $false
    Invoke-WinutilThemeChange -theme "Auto"
    $_.Handled = $false
  })
  # Define event handlers for menu items
$sync["DarkThemeMenuItem"].Add_Click({
    $sync.ThemePopup.IsOpen = $false
    Invoke-WinutilThemeChange -theme "Dark"
    $_.Handled = $false
  })
# Define event handlers for menu items
$sync["LightThemeMenuItem"].Add_Click({
    $sync.ThemePopup.IsOpen = $false
    Invoke-WinutilThemeChange -theme "Light"
    $_.Handled = $false
  })


# Define event handler for button click
$sync["SettingsButton"].Add_Click({
    Write-Debug "SettingsButton clicked"
    if ($sync.SettingsPopup.IsOpen) {
        $sync.SettingsPopup.IsOpen = $false
    }
    else{
        $sync.SettingsPopup.IsOpen = $true
    }
    $sync.ThemePopup.IsOpen = $false
    $_.Handled = $false
})

# Define event handlers for menu items
$sync["ImportMenuItem"].Add_Click({
  # Handle Import menu item click
  Write-Debug "Import clicked"
  $sync["SettingsPopup"].IsOpen = $false
  Invoke-WPFImpex -type "import"
  $_.Handled = $false
})

$sync["ExportMenuItem"].Add_Click({
    # Handle Export menu item click
    Write-Debug "Export clicked"
    $sync["SettingsPopup"].IsOpen = $false
    Invoke-WPFImpex -type "export"
    $_.Handled = $false
})

$sync["AboutMenuItem"].Add_Click({
    # Handle Export menu item click
    Write-Debug "About clicked"
    $sync["SettingsPopup"].IsOpen = $false
    $authorInfo = @"
Author   : <a href="https://github.com/ChrisTitusTech">@christitustech</a>
Runspace : <a href="https://github.com/DeveloperDurp">@DeveloperDurp</a>
MicroWin : <a href="https://github.com/KonTy">@KonTy</a>
GitHub   : <a href="https://github.com/ChrisTitusTech/winutil">ChrisTitusTech/winutil</a>
Version  : <a href="https://github.com/ChrisTitusTech/winutil/releases/tag/$($sync.version)">$($sync.version)</a>
"@

    Show-CustomDialog -Message $authorInfo -LogoSize $LogoSize
})

$sync["SponsorMenuItem"].Add_Click({
    # Handle Export menu item click
    Write-Debug "Sponsors clicked"
    $sync["SettingsPopup"].IsOpen = $false
    $authorInfo = @"
<a href="https://github.com/sponsors/ChrisTitusTech">Current sponsors for ChrisTitusTech:</a>
"@
    $authorInfo += "`n"
    try {
        # Call the function to get the sponsors
        $sponsors = Invoke-WinUtilSponsors

        # Append the sponsors to the authorInfo
        $sponsors | ForEach-Object { $authorInfo += "$_`n" }
    } catch {
        $authorInfo += "An error occurred while fetching or processing the sponsors: $_`n"
    }

    Show-CustomDialog -Message $authorInfo -EnableScroll $true
})

$sync["Form"].ShowDialog() | out-null
Stop-Transcript
