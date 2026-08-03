function Get-WinUtilSelectedPackages {

     param(
         [Parameter(Mandatory = $true)]
         [object] $PackageList,

         [Parameter(Mandatory = $true)]
         [string] $Preference
     )

    if ($PackageList.count -eq 1) {
        Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo" }
    } else {
        Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state "Normal" -value 0.01 -overlay "logo" }
    }

    $packagesWinget = [System.Collections.ArrayList]::new()
    $packagesChoco = [System.Collections.ArrayList]::new()
    $packagesPWA = [System.Collections.ArrayList]::new()  #Tâm thêm vào để add PWA app trong Microsoft store

    $packages = @{
        Winget = $packagesWinget
        Choco = $packagesChoco
        PWA = $packagesPWA #Tâm thêm vào để add PWA app trong Microsoft store
    }

    function Add-PackageId {
        param(
            [System.Collections.ArrayList]$Target,
            $PackageId
        )

        if ([string]::IsNullOrWhiteSpace([string]$PackageId) -or $PackageId -eq "na") {
            return
        }

        if (-not $Target.Contains($PackageId)) {
            $null = $Target.Add($PackageId)
        }
    }

    #Hàm Add-PWA được Tâm thêm để thêm các gói PWA vào danh sách cài đặt
  function Add-PWA {
    param(
        [System.Collections.ArrayList]$Target,
        $Package
    )

    if ($null -eq $Package.pwa) {
        return
    }

    if ([string]::IsNullOrWhiteSpace([string]$Package.pwa)) {
        return
    }

    $null = $Target.Add($Package)
}
    # đoạn foreach này có sẵn rồi, nhưng Tâm thêm vào đoạn if trước switch sẵn có để add PWA app trong Microsoft store
    foreach ($package in $PackageList) {
        #đoạn if này được Tâm thêm vào trước switch để add PWA app trong Microsoft store
            Write-WinUtilLog `-Component "Install" `-Message "DEBUG $($package.content) installType=$($package.installType)"
        if ($package.installType -eq "pwa") {
                                                Add-PWA `
                                                    -Target $packagesPWA `
                                                    -Package $package

                                                continue
            }
        switch ($Preference) {
            "Choco" {
                if ([string]::IsNullOrWhiteSpace([string]$package.choco) -or $package.choco -eq "na") {
                    Add-PackageId -Target $packagesWinget -PackageId $package.winget
                } else {
                    Add-PackageId -Target $packagesChoco -PackageId $package.choco
                }
            }
            "Winget" {
                Add-PackageId -Target $packagesWinget -PackageId $package.winget
            }
        }

    }

    return $packages
}
