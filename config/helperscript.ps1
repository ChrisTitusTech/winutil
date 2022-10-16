#This file is meant to assist in building out the json files inside this folder.

<#
    Applications.json
    -----------------
    This file holds all the winget commands to install the applications.
    It also has the ablity to expact to other frameworks (IE Choco).
    You can also add multiple winget commands by seperating them with ;

    The structure of the json is as follows

{
    "install": {
        "Name of Button": {
        "winget": "Winget command"
    },
}

Example:

{
    "install": {
        "Installadobe": {
            "winget": "Adobe.Acrobat.Reader.64-bit"
        },
        "Installadvancedip": {
            "winget": "Famatech.AdvancedIPScanner"
        }
    }
}

#>

#Modify the variables and run his code. It will import the current file and add your addition. From there you can create a pull request.

$NameofButton = "Installadobe"
$WingetCommand = "Adobe.Acrobat.Reader.64-bit"

$ButtonToAdd = New-Object psobject
$jsonfile = Get-Content ./config/applications.json | ConvertFrom-Json

Add-Member -InputObject $ButtonToAdd -MemberType NoteProperty -Name "Winget" -Value $WingetCommand
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

$NameofButton = "Featurenfs"
$commands = @(
    "ServicesForNFS-ClientOnly",
    "ClientForNFS-Infrastructure",
    "NFS-Administration"
)

$jsonfile = Get-Content ./config/feature.json | ConvertFrom-Json

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

$NameofButton = "minimal"
$commands = @(
    "EssTweaksHome",
    "EssTweaksOO",
    "EssTweaksRP",
    "EssTweaksServices",
    "EssTweaksTele"
)

$jsonfile = Get-Content ./config/preset.json | ConvertFrom-Json

Add-Member -InputObject $jsonfile -MemberType NoteProperty -Name $NameofButton -Value $commands

$jsonfile | ConvertTo-Json | Out-File ./config/preset.json