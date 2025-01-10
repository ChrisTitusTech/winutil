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
        if ($UseCmdlets) {
            $appxProvisionedPackages = Get-AppxProvisionedPackage -Path "$($scratchDir)" | Where-Object {
                    $_.PackageName -NotLike "*AppInstaller*" -AND
                    $_.PackageName -NotLike "*Store*" -and
                    $_.PackageName -NotLike "*Notepad*" -and
                    $_.PackageName -NotLike "*Printing*" -and
                    $_.PackageName -NotLike "*YourPhone*" -and
                    $_.PackageName -NotLike "*Xbox*" -and
                    $_.PackageName -NotLike "*WindowsTerminal*" -and
                    $_.PackageName -NotLike "*Calculator*" -and
                    $_.PackageName -NotLike "*Photos*" -and
                    $_.PackageName -NotLike "*VCLibs*" -and
                    $_.PackageName -NotLike "*Paint*" -and
                    $_.PackageName -NotLike "*Gaming*" -and
                    $_.PackageName -NotLike "*Extension*" -and
                    $_.PackageName -NotLike "*SecHealthUI*" -and
                    $_.PackageName -NotLike "*ScreenSketch*"
            }
        } else {
            $appxProvisionedPackages = dism /english /image="$scratchDir" /get-provisionedappxpackages | Select-String -Pattern "PackageName : " -CaseSensitive -SimpleMatch
            if ($?) {
                $appxProvisionedPackages = $appxProvisionedPackages -split "PackageName : " | Where-Object {$_}
                # Exclude the same items.
                $appxProvisionedPackages = $appxProvisionedPackages | Where-Object {
                    $_ -NotLike "*AppInstaller*" -AND
                    $_ -NotLike "*Store*" -and
                    $_ -NotLike "*Notepad*" -and
                    $_ -NotLike "*Printing*" -and
                    $_ -NotLike "*YourPhone*" -and
                    $_ -NotLike "*Xbox*" -and
                    $_ -NotLike "*WindowsTerminal*" -and
                    $_ -NotLike "*Calculator*" -and
                    $_ -NotLike "*Photos*" -and
                    $_ -NotLike "*VCLibs*" -and
                    $_ -NotLike "*Paint*" -and
                    $_ -NotLike "*Gaming*" -and
                    $_ -NotLike "*Extension*" -and
                    $_ -NotLike "*SecHealthUI*" -and
                    $_ -NotLike "*ScreenSketch*"
                }
            } else {
                Write-Host "AppX packages could not be obtained with DISM. MicroWin processing will continue, but AppX packages will be skipped."
                return
            }
        }

        $counter = 0
        if ($UseCmdlets) {
            foreach ($appx in $appxProvisionedPackages) {
                $status = "Removing Provisioned $($appx.PackageName)"
                Write-Progress -Activity "Removing Provisioned Apps" -Status $status -PercentComplete ($counter++/$appxProvisionedPackages.Count*100)
                try {
                    Remove-AppxProvisionedPackage -Path "$scratchDir" -PackageName $appx.PackageName -ErrorAction SilentlyContinue
                } catch {
                    Write-Host "Application $($appx.PackageName) could not be removed"
                    continue
                }
            }
        } else {
            foreach ($appx in $appxProvisionedPackages) {
                $status = "Removing Provisioned $appx"
                Write-Progress -Activity "Removing Provisioned Apps" -Status $status -PercentComplete ($counter++/$appxProvisionedPackages.Count*100)
                dism /english /image="$scratchDir" /remove-provisionedappxpackage /packagename=$appx /quiet /norestart | Out-Null
                if ($? -eq $false) {
                    Write-Host "AppX package $appx could not be removed."
                }
            }
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
