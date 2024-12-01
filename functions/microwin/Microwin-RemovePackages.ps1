function Microwin-RemovePackages {
    try {
        $pkglist = (Get-WindowsPackage -Path "$scratchDir").PackageName

        $pkglist = $pkglist | Where-Object {
                $_ -NotLike "*ApplicationModel*" -AND
                $_ -NotLike "*indows-Client-LanguagePack*" -AND
                $_ -NotLike "*LanguageFeatures-Basic*" -AND
                $_ -NotLike "*Package_for_ServicingStack*" -AND
                $_ -NotLike "*DotNet*" -AND
                $_ -NotLike "*Notepad*" -AND
                $_ -NotLike "*WMIC*" -AND
                $_ -NotLike "*Ethernet*" -AND
                $_ -NotLike "*Wifi*" -AND
                $_ -NotLike "*FodMetadata*" -AND
                $_ -NotLike "*Foundation*" -AND
                $_ -NotLike "*LanguageFeatures*" -AND
                $_ -NotLike "*VBSCRIPT*" -AND
                $_ -NotLike "*License*" -AND
                $_ -NotLike "*Hello-Face*" -AND
                $_ -NotLike "*ISE*"
            }

        $failedCount = 0

        $erroredPackages = [System.Collections.Generic.List[ErroredPackage]]::new()

        foreach ($pkg in $pkglist) {
            try {
                $status = "Removing $pkg"
                Write-Progress -Activity "Removing Packages" -Status $status -PercentComplete ($counter++/$pkglist.Count*100)
                Remove-WindowsPackage -Path "$scratchDir" -PackageName $pkg -NoRestart -ErrorAction SilentlyContinue
            } catch {
                # This can happen if the package that is being removed is a permanent one
                $erroredPackages.Add([ErroredPackage]::new($pkg, $_.Exception.Message))
                $failedCount += 1
                continue
            }
        }
        Write-Progress -Activity "Removing Packages" -Status "Ready" -Completed
        if ($failedCount -gt 0)
        {
            Write-Host "$failedCount package(s) could not be removed. Your image will still work fine, however. Below is information on what packages failed to be removed and why."
            if ($erroredPackages.Count -gt 0)
            {
                $erroredPackages = $erroredPackages | Sort-Object -Property ErrorMessage

                $previousErroredPackage = $erroredPackages[0]
                $counter = 0
                Write-Host ""
                Write-Host "- $($previousErroredPackage.ErrorMessage)"
                foreach ($erroredPackage in $erroredPackages) {
                    if ($erroredPackage.ErrorMessage -ne $previousErroredPackage.ErrorMessage) {
                        Write-Host ""
                        $counter = 0
                        Write-Host "- $($erroredPackage.ErrorMessage)"
                    }
                    $counter += 1
                    Write-Host "  $counter) $($erroredPackage.PackageName)"
                    $previousErroredPackage = $erroredPackage
                }
                Write-Host ""
            }
        }
    } catch {
        Write-Host "Unable to get information about the packages. MicroWin processing will continue, but packages will not be processed"
        Write-Host "Error information: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
