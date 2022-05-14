<#
.NOTES
   Author      : @DeveloperDurp
   GitHub      : https://github.com/DeveloperDurp
   Version 0.0.1
#>

#region Header

    #region Load .Net framwork

    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName PresentationFramework
    [System.Windows.Forms.Application]::EnableVisualStyles()

    #endregion Load .Net framework

    #Hiding Console Window
    <#
    Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
    '
    $consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 0) > $Null
    #>

#endregion Header

#region Functions

    #Instead of running the whole form in a run space I like to have it call the additional runspaces as 
    #I have found additional complexity when running forms outside of the main thread
    function Invoke-Button {
        Param ([string]$Button) 

        Switch -Wildcard ($Button){

            "*InstallProgram_Button*"{Invoke-Runspace $InstallScript}
        }
    }

    #You can call this function and pass a "powershell" script so that it can execute it inside a runspace.
    #Anything executed with this function will be able to interact with the $global:sync variable 
    #Another neat feature you can do with this method is updating the form itself assuming you created the form objects inside the $sync variable
    function Invoke-Runspace {
        Param ([string]$commands) 

        $Script = [PowerShell]::Create().AddScript($commands)

        $runspace = [RunspaceFactory]::CreateRunspace()
        $runspace.ApartmentState = "STA"
        $runspace.ThreadOptions = "ReuseThread"
        $runspace.Open()
        $runspace.SessionStateProxy.SetVariable("sync", $global:sync)

        $Script.Runspace = $runspace
        $Script.BeginInvoke()
    }

    #The prowershell gui scripts I build tend to be very daynamic in nature so I don't like to have a predefined layout like you do. 
    #This is one way for me to make sure things don't go too far down
    Function Check-Space {
        Param ([string]$cords)
        [int]$xint = ($cords -split ";")[0]
        [int]$yint = ($cords -split ";")[1]
        [int]$increment = ($cords -split ";")[2]

        if($yint -gt 650){Write-output "$($xint + 225)";10}
        if($yint -le 650){Write-output "$xint;$($yint + $increment)"}
    }

#endregion functions

#region Scripts

    #This is what you pass to the Invoke-Runspace function. This can interact with the $sync variable and even make changes that the main form will pickup. 
    #IE I could say $global:sync["InstallProgram_Browsers-LibreWolf_Checkbox"].text = "LibreWolf Installed"
    $InstallScript = {
        $programstoinstall = @()
        $global:sync.keys | Where-Object {$_ -like "InstallProgram_*_Checkbox"} | ForEach-Object {
            if($global:sync["$_"].checked -eq $true){
                $program = (($_ -split "_")[1] -split "-")[1]
                $programstoinstall += $program
            }

        }
        
        [System.Windows.MessageBox]::Show("I will install the following programs $programstoinstall",'Install Programs Button',"OK","Info")
    }

#endregion Scripts

$version = "0.0.1"
$ToolName = "winutil"
$formwidth = 1170
$formHeight = 800

$InstallPrograms = @(
    "Browsers;Brave,Google Chrome,Un-Googled Chromium, Firefox,LibreWolf,Vivaldi"
    "Communications;Discord,Hexchat,Matrix,Signal,Skype,Slack,Microsoft Teams,Zoom Video Conference"
    "Development;Atom,Github Desktop,OpenJDK Java 8,OpenJDK Java 16,Oracle Java 18,Jetbrains Toolbox,NodeJS,NodeJS LTS,Python3,Sublime,Visual Studio Code 2022 Community,VS Code,VS Codium"
    "Document;Adobe Reader DV,LibreOffice,Notepad++,Obsidian,Sumatra PDF"
    "Games;Epic Games Launcher,GOG Galaxy,Steam"
    "Pro Tools;Advanced IP Scanner,mRemoteNG,Putty,WinSCP,WireShark"
    "Multimedia Tools; Audacity,Blander (3D Graphics),Eartumpet (Audio),Flameshot (Screenshots),Foobar2000 (Music Player),Gimp (Image Editor),Greenshot (Screenshots),HandBrake,ImageGlass (Image Viewer),Inkscape,Media Player Classic (Video Player),OBS Studio,ShareX (Screenshots),Spotify,VLC (Video Player),Voicemeeter (Audio)"
    "Utilities;7-Zip,AnyDesk,AutoHotkey,Bitwarden,CPU-Z,Etcher USB Creator,Everything Search,GPU-Z,HWInfo,KeePassXC,MalwareBytes,NVCleanstall,Microsoft Powertoys,RevoUninstaller,Rufus Imager,TeamViewer,Translucent Taskbar,TreeSizeFree,WinDirStat,Windows Terminal"
)

$tabs = @(
       "Install"
       "Tweaks"
       "Config"
       "Updates" 
       "Help"
)

$global:sync = [Hashtable]::Synchronized(@{})

#region Form

$Form = New-Object system.Windows.Forms.Form
$Form.text = "$toolname $Version"
$form.AutoScroll = $True
$form.width = $formwidth
$form.Height = $formHeight
$Form.FormBorderStyle = 'Fixed3D'
$Form.MaximizeBox = $false
$Form.Add_FormClosing({
    Get-Process -Id $pid | Stop-Process
})

#For adding in an icon image
#$iconBase64 = ''
#$iconBytes = [Convert]::FromBase64String($iconBase64)
#$stream = New-Object IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
#$stream.Write($iconBytes, 0, $iconBytes.Length);
#$Form.Icon = [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap -Argument $stream).GetHIcon())

#endregion Form

#region Tab Control

    $tabcontrol = New-Object 'System.Windows.Forms.TabControl'
    $tabcontrol.Alignment = 'Top'
    $tabcontrol.Location = '0,0'
    $tabcontrol.Multiline = $True
    $tabcontrol.Name = 'tabcontrol'
    $tabcontrol.SelectedIndex = 0
    $tabcontrol.width = $formwidth
    $tabcontrol.Height = $($formHeight-35)
    $tabcontrol.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right -bor [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
    $tabcontrol.TabIndex = 0
    $Form.Controls.Add($tabcontrol)

#endregion Tab Control

#region Main Page

    foreach ($tab in $tabs){
        $page = New-Object 'System.Windows.Forms.TabPage'
        $page.name = "$tab"
        $page.text = "$tab"
        $tabcontrol.Controls.Add($page)
    }

    #Since I don't use an xaml file to create the gui (not sure how compatable that method is with this script as I have never used it) I create a loop to build everything.
    #You could do the same for the rest of the tabs in a similar fashion to this one.  

    #region Install Tab
        $x = 5
        $y = 10

        foreach($InstallProgram in $InstallPrograms){
            $group = ($InstallProgram -split ";")[0]
            $programs = ($InstallProgram -split ";")[1] -split ","

            $Label = New-Object Windows.Forms.Label
            $Label.Name = "$group"
            $Label.Location = New-Object System.Drawing.Point($x,$y)
            $Label.Font = 'Microsoft Sans Serif,15'
            $Label.Text = "$group"
            $Label.AutoSize = $true
            $tabcontrol.controls["Install"].Controls.Add($Label)
            
            $space = (Check-Space "$x;$y;40") -split ";"
            $x = $space[0]
            $y = $space[1]

            foreach($program in $programs){

                #The key here is adding the object to the $sync variable, this what allows powershell to interact with it while inside a runspace. 
                #IE $tabcontrol.controls["Install"] is not modifiable but $global:sync["InstallProgram_Browsers-LibreWolf_Checkbox"] is

                $object = New-Object Windows.Forms.Checkbox
                $object.Name = "InstallProgram_$group-$($program -replace " ","_")_Checkbox"
                $object.Font = 'Microsoft Sans Serif,8'
                $object.Location = New-Object System.Drawing.Point($x,$y)
                $object.Size = "225,20"
                $object.text = "$program"
                $object.checked = $false
                $global:sync["$($object.name)"] = $object
                $tabcontrol.Controls["Install"].Controls.Add($global:sync["$($object.name)"])

                $space = (Check-Space "$x;$y;20") -split ";"
                $x = $space[0]
                $y = $space[1]
            }          
            
            $y = [int]$y + 10
        }

        $space = (Check-Space "$x;9000;20") -split ";"
        $x = $space[0]
        $y = $space[1]

        $object = New-Object 'System.Windows.Forms.Button'
        $object.name = "InstallProgram_Button"
        $object.Location = New-Object System.Drawing.Point($x,$y)
        $object.Font = 'Microsoft Sans Serif,10'
        $object.Size = "200,25"
        $object.TextAlign = 'MiddleCenter'
        $object.text = "Install Programs"
        $object.Add_Click({
            #This took me a long time to figure out as my other scripts would create buttons dynamically. This will get the name of the button that you clicked 
            #then pass it to the Invoke-Button function above.

            [System.Object]$Sender = $args[0]

            Invoke-Button $Sender.name

        })
        $tabcontrol.controls["Install"].Controls.Add($object)

    #endregion Install Tab

    #region Help Page

    $Label = New-Object Windows.Forms.Label
    $Label.Name = "Help_Page_Label"
    $Label.Location = New-Object System.Drawing.Point(5,10)
    $Label.Font = 'Microsoft Sans Serif,15'
    $Label.Text = "Welcome to the Help Page"
    $Label.AutoSize = $true
    $tabcontrol.controls["help"].Controls.Add($Label)

    #endregion Help Page

#endregion Main Page

[Windows.Forms.Application]::Run($form)
