function Test-WinUtilPackageManager {
    <#

    .SYNOPSIS
        Checks if Winget and/or Choco are installed

    .PARAMETER winget
        Check if Winget is installed

    .PARAMETER choco
        Check if Chocolatey is installed

    #>

    Param(
        [System.Management.Automation.SwitchParameter]$winget,
        [System.Management.Automation.SwitchParameter]$choco
    )

    # Install Winget if not detected
    $wingetExists = Get-Command -Name winget -ErrorAction SilentlyContinue
    if ($wingetExists) {
        $wingetversionfull = (winget --version)
        $wingetversiontrim = $wingetversionfull.Trim('v')
        if ($wingetversiontrim.EndsWith("-preview")) {
            $wingetversiontrim = $wingetversiontrim.Trim('-preview')
            $wingetpreview = $true
        }
        $wingetVersion = [System.Version]::Parse($wingetversiontrim)
        $minimumWingetVersion = [System.Version]::new(1,2,10691) # Win 11 23H2 comes with bad winget v1.2.10691
        $wingetOutdated = $wingetVersion -le $minimumWingetVersion
        
        Write-Host "Winget $wingetVersionfull"
    }

    if (!$wingetExists -or $wingetOutdated) {
        if (!$wingetExists) {
            Write-Host "Winget not detected"
        } else {
            Write-Host "- Winget out-dated"
        } 
    }

    if ($winget) {
        if ($wingetExists -and !$wingetOutdated) {
            if (!$wingetpreview) {
                Write-Host "- Winget up-to-date"
            } else {
                Write-Host "- Winget preview version detected. Unexptected problems may occur" -ForegroundColor Yellow
            }
            return $true
        }
    }

    if ($choco) {
        if ((Get-Command -Name choco -ErrorAction Ignore) -and ($chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion)) {
            Write-Host "Chocolatey v$chocoVersion"
            return $true
        }
    }

    return $false
}
