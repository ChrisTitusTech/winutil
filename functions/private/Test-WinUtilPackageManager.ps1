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
        $wingetVersion = [System.Version]::Parse((winget --version).Trim('v'))
        $minimumWingetVersion = [System.Version]::new(1,2,10691) # Win 11 23H2 comes with bad winget v1.2.10691
        $wingetOutdated = $wingetVersion -le $minimumWingetVersion
        
        Write-Host "Winget v$wingetVersion"
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
            Write-Host "- Winget up-to-date"
            return $true
        }
    }

    if($choco){
        if ((Get-Command -Name choco -ErrorAction Ignore) -and ($chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion)){
            Write-Host "Chocolatey v$chocoVersion"
            return $true
        }
    }

    return $false
}