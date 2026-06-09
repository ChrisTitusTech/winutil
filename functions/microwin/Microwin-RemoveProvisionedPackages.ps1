function Microwin-RemoveProvisionedPackages() {
    <#
        .SYNOPSIS
        Removes AppX packages from a Windows image during MicroWin processing

        .PARAMETER UseCmdlets
            Determines whether or not to use the DISM cmdlets for processing.
            - If true, DISM cmdlets will be used
            - If false, calls to the DISM executable will be made whilst selecting bits and pieces from the output as a string (that was how MicroWin worked before
              the DISM conversion to cmdlets)

        .EXAMPLE
        Microwin-RemoveProvisionedPackages
    #>
    param (
        [Parameter(Mandatory = $true, Position = 0)] [bool]$UseCmdlets
    )
    try
    {
        $packages = & dism /English "/image:$ScratchDir" /Get-ProvisionedAppxPackages |
                ForEach-Object {
                    if ($_ -match 'PackageName : (.*)') { $matches[1] }
                }

            $packagePrefixes = @(
                'AppUp.IntelManagementandSecurityStatus',
                'Clipchamp.Clipchamp',
                'DolbyLaboratories.DolbyAccess',
                'DolbyLaboratories.DolbyDigitalPlusDecoderOEM',
                'Microsoft.BingNews',
                'Microsoft.BingSearch',
                'Microsoft.BingWeather',
                'Microsoft.Copilot',
                'Microsoft.Windows.CrossDevice',
                'Microsoft.GamingApp',
                'Microsoft.GetHelp',
                'Microsoft.Getstarted',
                'Microsoft.Microsoft3DViewer',
                'Microsoft.MicrosoftOfficeHub',
                'Microsoft.MicrosoftSolitaireCollection',
                'Microsoft.MicrosoftStickyNotes',
                'Microsoft.MixedReality.Portal',
                'Microsoft.MSPaint',
                'Microsoft.Office.OneNote',
                'Microsoft.OfficePushNotificationUtility',
                'Microsoft.OutlookForWindows',
                'Microsoft.Paint',
                'Microsoft.People',
                'Microsoft.PowerAutomateDesktop',
                'Microsoft.SkypeApp',
                'Microsoft.StartExperiencesApp',
                'Microsoft.Todos',
                'Microsoft.Wallet',
                'Microsoft.Windows.DevHome',
                'Microsoft.Windows.Copilot',
                'Microsoft.Windows.Teams',
                'Microsoft.WindowsAlarms',
                'Microsoft.WindowsCamera',
                'microsoft.windowscommunicationsapps',
                'Microsoft.WindowsFeedbackHub',
                'Microsoft.WindowsMaps',
                'Microsoft.WindowsSoundRecorder',
                'Microsoft.ZuneMusic',
                'Microsoft.ZuneVideo',
                'MicrosoftCorporationII.MicrosoftFamily',
                'MicrosoftCorporationII.QuickAssist',
                'MSTeams',
                'MicrosoftTeams'
            )

            $packagesToRemove = $packages | Where-Object {
                $pkg = $_
                $packagePrefixes | Where-Object { $pkg -like "*$_*" }
            }
            foreach ($package in $packagesToRemove) {
                & dism /English "/image:$ScratchDir" /Remove-ProvisionedAppxPackage "/PackageName:$package"
            }

        Write-Progress -Activity "Removing Provisioned Apps" -Status "Ready" -Completed
    }
    catch
    {
        Write-Host "Unable to get information about the AppX packages. A fallback will be used..."
        Write-Host "Error information: $($_.Exception.Message)" -ForegroundColor Yellow
        Microwin-RemoveProvisionedPackages -UseCmdlets $false
    }
}
