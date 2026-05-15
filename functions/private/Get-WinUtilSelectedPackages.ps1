function Get-WinUtilSelectedPackages {
     param(
         [Parameter(Mandatory = $true)]
         [object] $PackageList,
     
         [Parameter(Mandatory = $true)]
         [PackageManagers] $Preference
     )

    if ($PackageList.count -eq 1) {
        Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo" }
    } else {
        Invoke-WPFUIThread -ScriptBlock { Set-WinUtilTaskbaritem -state "Normal" -value 0.01 -overlay "logo" }
    }

    $packages = [System.Collections.Hashtable]::new()
    $packagesWinget = [System.Collections.ArrayList]::new()
    $packagesChoco = [System.Collections.ArrayList]::new()

    $packages[[PackageManagers]::Winget] = $packagesWinget
    $packages[[PackageManagers]::Choco] = $packagesChoco

    foreach ($package in $PackageList) {
          switch ($Preference) {
               "Choco" {
                    if ($package.choco -eq "na") {
                         $packagesWinget.add($($package.winget))
                    } else {
                         $packagesChoco.add($package.choco)
                    }
               }
               "Winget" {
                    if ($package.winget -eq "na") {
                         $packagesChoco.add($package.choco)
                    } else {
                         $packagesWinget.add($($package.winget))
                    }
               }
          }
     }
    return $packages
}
