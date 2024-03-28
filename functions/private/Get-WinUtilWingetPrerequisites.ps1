function Get-WinUtilWingetPrerequisites {
    <#
    .SYNOPSIS
        Downloads the Winget Prereqs.
    .DESCRIPTION
        Downloads Prereqs for Winget. Version numbers are coded as variables and can be updated as uncommonly as Microsoft updates the prereqs.
    #>

    # I don't know of a way to detect the prereqs automatically, so if someone has a better way of defining these, that would be great.
    # Microsoft.VCLibs version rarely changes, but for future compatibility I made it a variable.
    $versionVCLibs = "14.00"
    $fileVCLibs = "https://aka.ms/Microsoft.VCLibs.x64.${versionVCLibs}.Desktop.appx"
    # Write-Host "$fileVCLibs"
    # Microsoft.UI.Xaml version changed recently, so I made the version numbers variables.
    $versionUIXamlMinor = "2.8"
    $versionUIXamlPatch = "2.8.6"
    $fileUIXaml = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v${versionUIXamlPatch}/Microsoft.UI.Xaml.${versionUIXamlMinor}.x64.appx"
    # Write-Host "$fileUIXaml"

    Try{
        Write-Host "Downloading Microsoft.VCLibs Dependency..."
        Invoke-WebRequest -Uri $fileVCLibs -OutFile $ENV:TEMP\Microsoft.VCLibs.x64.Desktop.appx
        Write-Host "Downloading Microsoft.UI.Xaml Dependency...`n"
        Invoke-WebRequest -Uri $fileUIXaml -OutFile $ENV:TEMP\Microsoft.UI.Xaml.x64.appx
    }
    Catch{
        throw [WingetFailedInstall]::new('Failed to install prerequsites')
    }
}
