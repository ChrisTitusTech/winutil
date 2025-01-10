function Microwin-RemoveFeatures() {
    <#
        .SYNOPSIS
            Removes certain features from ISO image

        .PARAMETER UseCmdlets
            Determines whether or not to use the DISM cmdlets for processing.
            - If true, DISM cmdlets will be used
            - If false, calls to the DISM executable will be made whilst selecting bits and pieces from the output as a string (that was how MicroWin worked before
              the DISM conversion to cmdlets)

        .EXAMPLE
            Microwin-RemoveFeatures -UseCmdlets $true
    #>
    param (
        [Parameter(Mandatory = $true, Position = 0)] [bool]$UseCmdlets
    )
    try {
        if ($UseCmdlets) {
            $featlist = (Get-WindowsOptionalFeature -Path "$scratchDir")

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
        } else {
            $featList = dism /english /image="$scratchDir" /get-features | Select-String -Pattern "Feature Name : " -CaseSensitive -SimpleMatch
            if ($?) {
                $featList = $featList -split "Feature Name : " | Where-Object {$_}
                # Exclude the same items. Note: for now, this doesn't exclude those features that are disabled.
                # This will appear in the future
                $featList = $featList | Where-Object {
                    $_ -NotLike "*Defender*" -AND
                    $_ -NotLike "*Printing*" -AND
                    $_ -NotLike "*TelnetClient*" -AND
                    $_ -NotLike "*PowerShell*" -AND
                    $_ -NotLike "*NetFx*" -AND
                    $_ -NotLike "*Media*" -AND
                    $_ -NotLike "*NFS*" -AND
                    $_ -NotLike "*SearchEngine*" -AND
                    $_ -NotLike "*RemoteDesktop*"
                }
            } else {
                Write-Host "Features could not be obtained with DISM. MicroWin processing will continue, but features will be skipped."
                return
            }
        }

        if ($UseCmdlets) {
            foreach ($feature in $featList) {
                $status = "Removing feature $($feature.FeatureName)"
                Write-Progress -Activity "Removing features" -Status $status -PercentComplete ($counter++/$featlist.Count*100)
                Write-Debug "Removing feature $($feature.FeatureName)"
                Disable-WindowsOptionalFeature -Path "$scratchDir" -FeatureName $($feature.FeatureName) -Remove  -ErrorAction SilentlyContinue -NoRestart
            }
        } else {
            foreach ($feature in $featList) {
                $status = "Removing feature $feature"
                Write-Progress -Activity "Removing features" -Status $status -PercentComplete ($counter++/$featlist.Count*100)
                Write-Debug "Removing feature $feature"
                dism /english /image="$scratchDir" /disable-feature /featurename=$feature /remove /quiet /norestart | Out-Null
                if ($? -eq $false) {
                    Write-Host "Feature $feature could not be disabled."
                }
            }
        }
        Write-Progress -Activity "Removing features" -Status "Ready" -Completed
        Write-Host "You can re-enable the disabled features at any time, using either Windows Update or the SxS folder in <installation media>\Sources."
    } catch {
        Write-Host "Unable to get information about the features. A fallback will be used..."
        Write-Host "Error information: $($_.Exception.Message)" -ForegroundColor Yellow
        Microwin-RemoveFeatures -UseCmdlets $false
    }
}
