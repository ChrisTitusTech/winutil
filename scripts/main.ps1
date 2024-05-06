# SPDX-License-Identifier: MIT
# Set the maximum number of threads for the RunspacePool to the number of threads on the machine
$maxthreads = [int]$env:NUMBER_OF_PROCESSORS

# Create a new session state for parsing variables into our runspace
$hashVars = New-object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'sync',$sync,$Null
$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

# Add the variable to the session state
$InitialSessionState.Variables.Add($hashVars)

# Get every private function and add them to the session state
$functions = Get-ChildItem function:\ | Where-Object {$_.name -like "*winutil*" -or $_.name -like "*WPF*"}
foreach ($function in $functions){
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
        [string] $additionalData

        WingetFailedInstall($Message) : base($Message) {}
    }

    class ChocoFailedInstall : Exception {
        [string] $additionalData

        ChocoFailedInstall($Message) : base($Message) {}
    }

    class GenericException : Exception {
        [string] $additionalData

        GenericException($Message) : base($Message) {}
    }


$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'

if ((Get-WinUtilToggleStatus WPFToggleDarkMode) -eq $True) {
    if (Invoke-WinUtilGPU -eq $True) {
        $ctttheme = 'Matrix'
    }
    else {
        $ctttheme = 'Dark'
    }
}
else {
    $ctttheme = 'Classic'
}
$inputXML = Set-WinUtilUITheme -inputXML $inputXML -themeName $ctttheme

[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML

# Read the XAML file
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try { $sync["Form"] = [Windows.Markup.XamlReader]::Load( $reader ) }
catch [System.Management.Automation.MethodInvocationException] {
    Write-Warning "We ran into a problem with the XAML code.  Check the syntax for this control..."
    Write-Host $error[0].Exception.Message -ForegroundColor Red
    If ($error[0].Exception.Message -like "*button*") {
        write-warning "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n"
    }
}
catch {
    Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
}

#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {$sync["$("$($psitem.Name)")"] = $sync["Form"].FindName($psitem.Name)}

$sync.keys | ForEach-Object {
    if($sync.$psitem){
        if($($sync["$psitem"].GetType() | Select-Object -ExpandProperty Name) -eq "CheckBox" `
                -and $sync["$psitem"].Name -like "WPFToggle*"){
            $sync["$psitem"].IsChecked = Get-WinUtilToggleStatus $sync["$psitem"].Name

            $sync["$psitem"].Add_Click({
                [System.Object]$Sender = $args[0]
                Invoke-WPFToggle $Sender.name
            })
        }

        if($($sync["$psitem"].GetType() | Select-Object -ExpandProperty Name) -eq "ToggleButton"){
            $sync["$psitem"].Add_Click({
                [System.Object]$Sender = $args[0]
                Invoke-WPFButton $Sender.name
            })
        }

        if($($sync["$psitem"].GetType() | Select-Object -ExpandProperty Name) -eq "Button"){
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
    $sync.ConfigLoaded = $False
    $sync.ComputerInfo = Get-ComputerInfo
    $sync.ConfigLoaded = $True
} | Out-Null

#===========================================================================
# Setup and Show the Form
#===========================================================================

# Print the logo
Invoke-WPFFormVariables

# Check if Chocolatey is installed
Install-WinUtilChoco

# Set the titlebar
$sync["Form"].title = $sync["Form"].title + " " + $sync.version
# Set the commands that will run when the form is closed
$sync["Form"].Add_Closing({
    $sync.runspace.Dispose()
    $sync.runspace.Close()
    [System.GC]::Collect()
})

# Attach the event handler to the Click event
$sync.CheckboxFilterClear.Add_Click({
    $sync.CheckboxFilter.Text = ""
    $sync.CheckboxFilterClear.Visibility = "Collapsed"
})

# add some shortcuts for people that don't like clicking
$commonKeyEvents = {
    if ($sync.ProcessRunning -eq $true) {
        return
    }

    if ($_.Key -eq "Escape")
    {
        $sync.CheckboxFilter.SelectAll()
        $sync.CheckboxFilter.Text = ""
        $sync.CheckboxFilterClear.Visibility = "Collapsed"
        return
    }

    # don't ask, I know what I'm doing, just go...
    if (($_.Key -eq "Q" -and $_.KeyboardDevice.Modifiers -eq "Ctrl"))
    {
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
        if ($sync.CheckboxFilter.Text -eq "Ctrl-F to filter") {
            $sync.CheckboxFilter.SelectAll()
            $sync.CheckboxFilter.Text = ""
        }
        $sync.CheckboxFilter.Focus()
    }
}

$sync["Form"].Add_PreViewKeyDown($commonKeyEvents)

$sync["Form"].Add_MouseLeftButtonDown({
    if ($sync["SettingsPopup"].IsOpen) {
        $sync["SettingsPopup"].IsOpen = $false
    }
    $sync["Form"].DragMove()
})

$sync["Form"].Add_MouseDoubleClick({
    if ($sync["Form"].WindowState -eq [Windows.WindowState]::Normal)
    {
        $sync["Form"].WindowState = [Windows.WindowState]::Maximized;
    }
    else
    {
        $sync["Form"].WindowState = [Windows.WindowState]::Normal;
    }
})

$sync["Form"].Add_Deactivated({
    Write-Debug "WinUtil lost focus"
    if ($sync["SettingsPopup"].IsOpen) {
        $sync["SettingsPopup"].IsOpen = $false
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

    foreach ($proc in (Get-Process | Where-Object { $_.MainWindowTitle -and $_.MainWindowTitle -like "*titus*" })) {
        if ($proc.Id -ne [System.IntPtr]::Zero) {
            Write-Debug "MainWindowHandle: $($proc.Id) $($proc.MainWindowTitle) $($proc.MainWindowHandle)"
            $windowHandle = $proc.MainWindowHandle
        }
    }

    # need to experiemnt more
    # setting icon for the windows is still not working
    # $pngUrl = "https://christitus.com/images/logo-full.png"
    # $pngPath = "$env:TEMP\cttlogo.png"
    # $iconPath = "$env:TEMP\cttlogo.ico"
    # # Download the PNG file
    # Invoke-WebRequest -Uri $pngUrl -OutFile $pngPath
    # if (Test-Path -Path $pngPath) {
    #     ConvertTo-Icon -bitmapPath $pngPath -iconPath $iconPath
    # }
    # $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)
    # Write-Host $icon.Handle
    # [Window]::SendMessage($windowHandle, 0x80, [IntPtr]::Zero, $icon.Handle)

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
    if ($PARAM_CONFIG){
        Invoke-WPFImpex -type "import" -Config $PARAM_CONFIG
        if ($PARAM_RUN){
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

$sync["CheckboxFilter"].Add_TextChanged({

    if ($sync.CheckboxFilter.Text -ne "") {
        $sync.CheckboxFilterClear.Visibility = "Visible"
    }
    else {
        $sync.CheckboxFilterClear.Visibility = "Collapsed"
    }

    $filter = Get-WinUtilVariables -Type CheckBox
    $CheckBoxes = $sync.GetEnumerator() | Where-Object { $psitem.Key -in $filter }

    foreach ($CheckBox in $CheckBoxes) {
        # Check if the checkbox is null or if it doesn't have content
        if ($CheckBox -eq $null -or $CheckBox.Value -eq $null -or $CheckBox.Value.Content -eq $null) {
            continue
        }

        $textToSearch = $sync.CheckboxFilter.Text.ToLower()
        $checkBoxName = $CheckBox.Key
        $textBlockName = $checkBoxName + "Link"

        # Retrieve the corresponding text block based on the generated name
        $textBlock = $sync[$textBlockName]

        if ($CheckBox.Value.Content.ToLower().Contains($textToSearch)) {
            $CheckBox.Value.Visibility = "Visible"
             # Set the corresponding text block visibility
            if ($textBlock -ne $null) {
                $textBlock.Visibility = "Visible"
            }
        }
        else {
             $CheckBox.Value.Visibility = "Collapsed"
            # Set the corresponding text block visibility
            if ($textBlock -ne $null) {
                $textBlock.Visibility = "Collapsed"
            }
        }
    }

})

# Define event handler for button click
$sync["SettingsButton"].Add_Click({
    Write-Debug "SettingsButton clicked"
    if ($sync["SettingsPopup"].IsOpen) {
        $sync["SettingsPopup"].IsOpen = $false
    }
    else {
        $sync["SettingsPopup"].IsOpen = $true
    }
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
    # Example usage
    $authorInfo = @"
Author   : @christitustech
Runspace : @DeveloperDurp
GUI      : @KonTy
MicroWin : @KonTy
GitHub   : https://github.com/ChrisTitusTech/winutil
Version  : $($sync.version)
"@
    Show-CustomDialog -Message $authorInfo -Width 400
})

$sync["Form"].ShowDialog() | out-null
Stop-Transcript
