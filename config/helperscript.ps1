#This file is meant to assist in building out the json files inside this folder.

<#
    Applications.json
    -----------------
    This file holds all the install commands to install the applications.
    This file has the ability to expect multiple frameworks per checkbox.
    You can also add multiple install commands by seperating them with ;

    The structure of the json is as follows

{
    "install": {
        "Name of Button": {
            "winget": "Winget command"
            "choco": "Chocolatey command"
    },
}

Example:

{
    "install": {
        "WPFInstalladobe": {
            "winget": "Adobe.Acrobat.Reader.64-bit"
            "choco": "adobereader"
        },
        "WPFInstalladvancedip": {
            "winget": "Famatech.AdvancedIPScanner"
            "choco": "advanced-ip-scanner"
        }
    }
}

#>

#Modify the variables and run his code. It will import the current file and add your addition. From there you can create a pull request.
#------Do not delete WPF------

$NameofButton = "WPF" + ""
$WingetCommand = ""
$ChocoCommand = ""

$ButtonToAdd = New-Object psobject
$jsonfile = Get-Content ./config/applications.json | ConvertFrom-Json

#remove if already exists
if($jsonfile.install.$NameofButton){
    $jsonfile.install.psobject.Properties.remove($NameofButton)
}

Add-Member -InputObject $ButtonToAdd -MemberType NoteProperty -Name "Winget" -Value $WingetCommand
Add-Member -InputObject $ButtonToAdd -MemberType NoteProperty -Name "choco" -Value $ChocoCommand
Add-Member -InputObject $jsonfile.install -MemberType NoteProperty -Name $NameofButton -Value $ButtonToAdd

$jsonfile | ConvertTo-Json | Out-File ./config/applications.json

<#
    feature.json
    -----------------
    This file holds all the windows commands to install specefic features (IE Hyper-v)

    The structure of the json is as follows

{
    "Name of Button": [
        "Array of",
        "commands"
    ]
}

Example:
{
    "Featurewsl": [
        "VirtualMachinePlatform",
        "Microsoft-Windows-Subsystem-Linux"
    ],
    "Featurenfs": [
        "ServicesForNFS-ClientOnly",
        "ClientForNFS-Infrastructure",
        "NFS-Administration"
    ]
}    
#>

#Modify the variables and run his code. It will import the current file and add your addition. From there you can create a pull request.

$NameofButton = ""
$commands = @(

)

$jsonfile = Get-Content ./config/feature.json | ConvertFrom-Json

#remove if already exists
if($jsonfile.$NameofButton){
    $jsonfile.psobject.Properties.remove($NameofButton)
}

Add-Member -InputObject $jsonfile -MemberType NoteProperty -Name $NameofButton -Value $commands

$jsonfile | ConvertTo-Json | Out-File ./config/feature.json

<#
    preset.json
    -----------------
    This file holds all check boxes you wish to check when clicking a preset button in the tweaks section.

    The structure of the json is as follows

{
    "Name of Button": [
        "Array of",
        "checkboxes to check"
    ]
}

Example:
{
    "laptop": [
        "EssTweaksAH",
        "EssTweaksDVR",
        "EssTweaksHome",
        "EssTweaksLoc",
        "EssTweaksOO",
        "EssTweaksRP",
        "EssTweaksServices",
        "EssTweaksStorage",
        "EssTweaksTele",
        "EssTweaksWifi",
        "MiscTweaksLapPower",
        "MiscTweaksLapNum"
    ],
    "minimal": [
        "EssTweaksHome",
        "EssTweaksOO",
        "EssTweaksRP",
        "EssTweaksServices",
        "EssTweaksTele"
    ]
}    
#>

#Modify the variables and run his code. It will import the current file and add your addition. From there you can create a pull request.

$NameofButton = "WPF" + ""
$commands = @(
    
)

$jsonfile = Get-Content ./config/preset.json | ConvertFrom-Json

#remove if already exists
if($jsonfile.$NameofButton){
    $jsonfile.psobject.Properties.remove($NameofButton)
}

Add-Member -InputObject $jsonfile -MemberType NoteProperty -Name $NameofButton -Value $commands

$jsonfile | ConvertTo-Json | Out-File ./config/preset.json

<#
    tweaks.json
    -----------------
    This file holds all the tweaks needed to make modifications to windows. This file is the most complicated so modify with care.

    The structure of the json is as follows

{
    "Name of button": {
        "registry" : [
            {
                "Path":  "Path in registry",
                "Name":  "Name of Registry key",
                "Type": "Item type",
                "Value":  "Value to modify", 
                "OriginalValue": "value to reset"
            }
        ],
        "service" : [
            {
                "Name":  "Name of service",
                "StartupType":  "Startup type to set", 
                "OriginalType": "Startup type to reset"
            }
        ],
        "ScheduledTask" : [
            {
                "Name":  "Path to scheduled task",
                "State":  "State to set", 
                "OriginalState": "State to reset"
            }
        ],
        "appx": [
            List of appx,
            files to uninstall
        ],
        "InvokeScript": [
            "Script to make modifications not possible with the above types
            Special care needs to be taken here as converting from json to a scriptblock
            can cause weird issues. Please look at the example below to get an idea of how things should work"                 
        ],
        "UndoScript": [
            "Same as above however is meant to undo what you did above"                 
        ]
    }
}

Example:

{
    EssTweaksAH": {
        "registry" : [
            {
                "Path":  "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
                "Name":  "EnableActivityFeed",
                "Type": "DWord",
                "Value":  "0", 
                "OriginalValue": "1"
            },
            {
                "Path":  "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\System",
                "Name":  "PublishUserActivities",
                "Type": "DWord",
                "Value":  "0", 
                "OriginalValue": "1"
            }
        ]
    },
    "EssTweaksHome": {
        "service" : [
            {
                "Name":  "HomeGroupListener",
                "StartupType":  "Manual", 
                "OriginalType": "Automatic"
            },
            {
                "Name":  "HomeGroupProvider",
                "StartupType":  "Manual", 
                "OriginalType": "Automatic"
            }
        ]
    },
    "EssTweaksTele": {
        "ScheduledTask" : [
            {
                "Name":  "Microsoft\\Windows\\Application Experience\\Microsoft Compatibility Appraiser",
                "State":  "Disabled", 
                "OriginalState": "Enabled"
            },                    
            {
                "Name":  "Microsoft\\Windows\\Application Experience\\ProgramDataUpdater",
                "State":  "Disabled", 
                "OriginalState": "Enabled"
            }
        ]
    },
    "EssTweaksDeBloat": {
        "appx": [
            "Microsoft.Microsoft3DViewer",
            "Microsoft.AppConnector"
        ]
    },
    "EssTweaksOO": {
        "InvokeScript": [
            "Import-Module BitsTransfer
            Start-BitsTransfer -Source \"https://raw.githubusercontent.com/ChrisTitusTech/win10script/master/ooshutup10.cfg\" -Destination C:\\Windows\\Temp\\ooshutup10.cfg
            Start-BitsTransfer -Source \"https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe\" -Destination C:\\Windows\\Temp\\OOSU10.exe
            C:\\Windows\\Temp\\OOSU10.exe C:\\Windows\\Temp\\ooshutup10.cfg /quiet"                 
        ]
    }
}

#>

#Modify the variables and run his code. It will import the current file and add your addition. From there you can create a pull request.
#Make sure to uncomment the sections you which to add.

$NameofButton = ""

#$Registry = @(
#    #to add more repeat this seperated by a comma
#    @{
#        Path = ""
#        Name = ""
#        Type = ""
#        Value = ""
#        OriginalValue = ""
#    }
#)

#$Service = @(
#    #to add more repeat this seperated by a comma
#    @{
#        Name = ""
#        StartupType = ""
#        OriginalType = ""
#    }
#)

#$ScheduledTask = @(
#    #to add more repeat this seperated by a comma
#    @{
#        Name = ""
#        State = ""
#        OriginalState = ""
#    }
#)

#$Appx = @(
#    ""
#)

#$InvokeScript = @(
#    "" 
#)

#$UndoScript = @(
#    "" 
#)

$ButtonToAdd = New-Object psobject
$jsonfile = Get-Content ./config/tweaks.json | ConvertFrom-Json

#remove if already exists
if($jsonfile.$NameofButton){
    $jsonfile.psobject.Properties.remove($NameofButton)
}

if($Registry){Add-Member -InputObject $ButtonToAdd -MemberType NoteProperty -Name "registry" -Value $Registry}
if($Service){Add-Member -InputObject $ButtonToAdd -MemberType NoteProperty -Name "service" -Value $Service}
if($ScheduledTask){Add-Member -InputObject $ButtonToAdd -MemberType NoteProperty -Name "ScheduledTask" -Value $ScheduledTask}
if($Appx){Add-Member -InputObject $ButtonToAdd -MemberType NoteProperty -Name "Appx" -Value $Appx}
if($InvokeScript){Add-Member -InputObject $ButtonToAdd -MemberType NoteProperty -Name "InvokeScript" -Value $InvokeScript}
if($UndoScript){Add-Member -InputObject $ButtonToAdd -MemberType NoteProperty -Name "UndoScript" -Value $UndoScript}

Add-Member -InputObject $jsonfile -MemberType NoteProperty -Name $NameofButton -Value $ButtonToAdd

($jsonfile | ConvertTo-Json -Depth 5).replace('\r\n',"`r`n") | Out-File ./config/tweaks.json
