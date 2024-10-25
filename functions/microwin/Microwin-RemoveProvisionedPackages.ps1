function Microwin-RemoveProvisionedPackages() {
    <#
        .SYNOPSIS
        Removes AppX packages from a Windows image during MicroWin processing

        .PARAMETER Name
        No Params

        .EXAMPLE
        Microwin-RemoveProvisionedPackages
    #>
    try
    {
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

        $counter = 0
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
        Write-Progress -Activity "Removing Provisioned Apps" -Status "Ready" -Completed
    }
    catch
    {
        # This can happen if getting AppX packages fails
        Write-Host "Unable to get information about the AppX packages. MicroWin processing will continue, but AppX packages will not be processed"
        Write-Host "Error information: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
