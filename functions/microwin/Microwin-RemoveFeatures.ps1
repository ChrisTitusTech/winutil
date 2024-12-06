function Microwin-RemoveFeatures() {
    <#
        .SYNOPSIS
            Removes certain features from ISO image

        .PARAMETER Name
            No Params

        .EXAMPLE
            Microwin-RemoveFeatures
    #>
    try {
        $featlist = (Get-WindowsOptionalFeature -Path $scratchDir)

        $featlist = $featlist | Where-Object {
            $_.FeatureName -NotLike "*Defender*" -AND
            $_.FeatureName -NotLike "*Printing*" -AND
            $_.FeatureName -NotLike "*TelnetClient*" -AND
            $_.FeatureName -NotLike "*PowerShell*" -AND
            $_.FeatureName -NotLike "*NetFx*" -AND
            $_.FeatureName -NotLike "*Media*" -AND
            $_.FeatureName -NotLike "*NFS*" -AND
            $_.FeatureName -NotLike "*SearchEngine*" -AND
            $_.FeatureName -NotLike "*RemoteDesktop*" -AND
            $_.State -ne "Disabled"
        }

        foreach($feature in $featlist) {
            $status = "Removing feature $($feature.FeatureName)"
            Write-Progress -Activity "Removing features" -Status $status -PercentComplete ($counter++/$featlist.Count*100)
            Write-Debug "Removing feature $($feature.FeatureName)"
            Disable-WindowsOptionalFeature -Path "$scratchDir" -FeatureName $($feature.FeatureName) -Remove  -ErrorAction SilentlyContinue -NoRestart
        }
        Write-Progress -Activity "Removing features" -Status "Ready" -Completed
        Write-Host "You can re-enable the disabled features at any time, using either Windows Update or the SxS folder in <installation media>\Sources."
    } catch {
        Write-Host "Unable to get information about the features. MicroWin processing will continue, but features will not be processed"
        Write-Host "Error information: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
