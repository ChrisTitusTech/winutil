function Microwin-RemovePackages {
    <#
        .SYNOPSIS
            Removes certain packages from ISO image

        .PARAMETER UseCmdlets
            Determines whether or not to use the DISM cmdlets for processing.
            - If true, DISM cmdlets will be used
            - If false, calls to the DISM executable will be made whilst selecting bits and pieces from the output as a string (that was how MicroWin worked before
              the DISM conversion to cmdlets)

        .EXAMPLE
            Microwin-RemovePackages -UseCmdlets $true
    #>
    param (
        [Parameter(Mandatory = $true, Position = 0)] [bool]$UseCmdlets
    )
    try {
        if ($useCmdlets) {
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
                    $_ -NotLike "*ISE*" -AND
                    $_ -NotLike "*OpenSSH*"
                }
        } else {
            $pkgList = dism /english /image="$scratchDir" /get-packages | Select-String -Pattern "Package Identity : " -CaseSensitive -SimpleMatch
            if ($?) {
                $pkgList = $pkgList -split "Package Identity : " | Where-Object {$_}
                # Exclude the same items.
                $pkgList = $pkgList | Where-Object {
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
                    $_ -NotLike "*ISE*" -AND
                    $_ -NotLike "*OpenSSH*"
                }
            } else {
                Write-Host "Packages could not be obtained with DISM. MicroWin processing will continue, but packages will be skipped."
                return
            }
        }

        if ($UseCmdlets) {
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
        } else {
            foreach ($package in $pkgList) {
                $status = "Removing package $package"
                Write-Progress -Activity "Removing Packages" -Status $status -PercentComplete ($counter++/$pkglist.Count*100)
                Write-Debug "Removing package $package"
                dism /english /image="$scratchDir" /remove-package /packagename=$package /remove /quiet /norestart | Out-Null
                if ($? -eq $false) {
                    Write-Host "Package $package could not be removed."
                }
            }
        }
        Write-Progress -Activity "Removing Packages" -Status "Ready" -Completed
        if ($UseCmdlets -and $failedCount -gt 0)
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
        Write-Host "Unable to get information about the packages. A fallback will be used..."
        Write-Host "Error information: $($_.Exception.Message)" -ForegroundColor Yellow
        Microwin-RemovePackages -UseCmdlets $false
    }
}
