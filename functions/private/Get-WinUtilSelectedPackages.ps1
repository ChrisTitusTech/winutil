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
        $target = if ($Preference -eq "Choco" -and $package.choco -ne "na") { "Choco" } elseif ($package.winget -ne "na") { "Winget" } elseif ($package.choco -ne "na") { "Choco" }
        if ($target) { $null = $packages[[PackageManagers]$target].add($package.$($target.ToLower())) }
    }

    return $packages
}
