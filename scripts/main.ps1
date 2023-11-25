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

if ((Get-WinUtilToggleStatus WPFToggleDarkMode) -eq $True){
    $ctttheme = 'Matrix'
}
Else{
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
        if($($sync["$psitem"].GetType() | Select-Object -ExpandProperty Name) -eq "Button"){
            $sync["$psitem"].Add_Click({
                [System.Object]$Sender = $args[0]
                Invoke-WPFButton $Sender.name
            })
        }
    }
}

$sync.keys | ForEach-Object {
    if($sync.$psitem){
        if($($sync["$psitem"].GetType() | Select-Object -ExpandProperty Name) -eq "ToggleButton"){
            $sync["$psitem"].Add_Click({
                [System.Object]$Sender = $args[0]
                Invoke-WPFButton $Sender.name
            })
        }
    }
}

$sync.keys | ForEach-Object {
    if($sync.$psitem){
        if(
            $($sync["$psitem"].GetType() | Select-Object -ExpandProperty Name) -eq "CheckBox" `
            -and $sync["$psitem"].Name -like "WPFToggle*"
        ){
            $sync["$psitem"].IsChecked = Get-WinUtilToggleStatus $sync["$psitem"].Name

            $sync["$psitem"].Add_Click({
                [System.Object]$Sender = $args[0]
                Invoke-WPFToggle $Sender.name
            })
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

# add some shortcuts for people that don't like clicking
$commonKeyEvents = {
    if ($sync.ProcessRunning -eq $true) {
        return
    }

    # Escape removes focus from the searchbox that way all shortcuts will start workinf again
    if ($_.Key -eq "Escape") {
        if ($sync.CheckboxFilter.IsFocused)
        {
            $sync.CheckboxFilter.SelectAll()
            $sync.CheckboxFilter.Text = ""
            $sync.CheckboxFilter.Focus()
            return
        }
    }

    # don't ask, I know what I'm doing, just go...
    if (($_.Key -eq "Q" -and $_.KeyboardDevice.Modifiers -eq "Ctrl"))
    {
        $this.Close()
    }

    # $ret = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to Exit?", "Winutil", [System.Windows.Forms.MessageBoxButtons]::YesNo,
    # [System.Windows.Forms.MessageBoxIcon]::Question, [System.Windows.Forms.MessageBoxDefaultButton]::Button2) 

    # switch ($ret) {
    #     "Yes" {
    #         $this.Close()
    #     } 
    #     "No" {
    #         return
    #     } 
    # }


    if ($_.KeyboardDevice.Modifiers -eq "Alt") {
        # this is an example how to handle shortcuts per tab
        # Alt-I on the MicroWin tab (4) would press GetIso Button
        # NOTE: All per tab shortcuts have to be handled *before* regular tab keys
        # if ($_.SystemKey -eq "I") {
        #     $TabNav = Get-WinUtilVariables | Where-Object {$psitem -like "WPFTabNav"}
        #     if ($sync.$TabNav.Items[4].IsSelected -eq $true) {
        #         Invoke-WPFButton "WPFGetIso"
        #         break
        #     }
        # }
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

# adding some left mouse window move on drag capability
$sync["Form"].Add_MouseLeftButtonDown({
    $sync["Form"].DragMove()
})

# setting window icon to make it look more professional
$sync["Form"].Add_Loaded({
   
    $downloadUrl = "https://christitus.com/images/logo-full.png"
    $destinationPath = Join-Path $env:TEMP "cttlogo.png"
    
    # Check if the file already exists
    if (-not (Test-Path $destinationPath)) {
        # File does not exist, download it
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($downloadUrl, $destinationPath)
        Write-Output "File downloaded to: $destinationPath"
    } else {
        Write-Output "File already exists at: $destinationPath"
    }
    $sync["Form"].Icon = $destinationPath

    Try { 
        [Void][Window]
    } Catch {
        Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        public class Window {
            [DllImport("user32.dll")]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
            [DllImport("user32.dll")]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw);
            [DllImport("user32.dll")]
            [return: MarshalAs(UnmanagedType.Bool)]
            public static extern bool ShowWindow(IntPtr handle, int state);
        }
        public struct RECT {
            public int Left;   // x position of upper-left corner
            public int Top;    // y position of upper-left corner
            public int Right;  // x position of lower-right corner
            public int Bottom; // y position of lower-right corner
        }
"@
    }
    
    $processId  = [System.Diagnostics.Process]::GetCurrentProcess().Id
    $windowHandle  = (Get-Process -Id $processId).MainWindowHandle
    $rect = New-Object RECT
    [Void][Window]::GetWindowRect($windowHandle,[ref]$rect)
    
    # only snap upper edge don't move left to right, in case people have multimon setup
    $x = $rect.Left
    $y = 0
    $width  = $rect.Right  - $rect.Left
    $height = $rect.Bottom - $rect.Top
    
    # Move the window to that position...
    [Void][Window]::MoveWindow($windowHandle, $x, $y, $width, $height, $True)
    Invoke-WPFTab "WPFTab1BT"
    $sync["Form"].Focus()
})

$sync["CheckboxFilter"].Add_TextChanged({
    #Write-host $sync.CheckboxFilter.Text

    $filter = Get-WinUtilVariables -Type Checkbox
    $CheckBoxes = $sync.GetEnumerator() | Where-Object {$psitem.Key -in $filter}
    $textToSearch = $sync.CheckboxFilter.Text
    Foreach ($CheckBox in $CheckBoxes) {
        #Write-Host "$($sync.CheckboxFilter.Text)"
        if ($CheckBox -eq $null -or $CheckBox.Value -eq $null -or $CheckBox.Value.Content -eq $null) { 
            continue
        }
         if ($CheckBox.Value.Content.ToLower().Contains($textToSearch)) {
             $CheckBox.Value.Visibility = "Visible"
         }
         else {
             $CheckBox.Value.Visibility = "Collapsed"
         }
     }
})


$downloadUrl = "https://christitus.com/images/logo-full.png"
$destinationPath = Join-Path $env:TEMP "cttlogo.png"

# Check if the file already exists
if (-not (Test-Path $destinationPath)) {
    # File does not exist, download it
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($downloadUrl, $destinationPath)
    Write-Output "File downloaded to: $destinationPath"
} else {
    Write-Output "File already exists at: $destinationPath"
}

# show current windowsd Product ID
#Write-Host "Your Windows Product Key: $((Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey)"

$sync["Form"].ShowDialog() | out-null
Stop-Transcript