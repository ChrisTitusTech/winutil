function Install-WinUtilProgramChoco {
    <#
    .SYNOPSIS
    Manages the provided programs using Chocolatey
    
    .PARAMETER ProgramsToInstall
    A list of programs to manage
    
    .PARAMETER manage
    The action to perform on the programs, can be either 'Installing' or 'Uninstalling'
    
    .NOTES
    The triple quotes are required any time you need a " in a normal script block.
    #>
    
    param(
    $ProgramsToInstall,
    $manage = "Installing"
    )
    
    $x = 0
    $count = $ProgramsToInstall.Count
    
    Write-Progress -Activity "$manage Applications" -Status "Starting" -PercentComplete 0
    Write-Host "==========================================="
    Write-Host "--   insstalling Chocolatey pacakages   ---"
    Write-Host "==========================================="
    Foreach ($Program in $ProgramsToInstall){
        Write-Progress -Activity "$manage Applications" -Status "$manage $($Program.choco) $($x + 1) of $count" -PercentComplete $($x/$count*100)
        if($manage -eq "Installing"){
            write-host "Starting install of $($Program.choco) with Chocolatey."
            try{
                $tryUpgrade = $false
		$installOutputFilePath = "$env:TEMP\Install-WinUtilProgramChoco.install-command.output.txt"
		$chocoInstallStatus = $(Start-Process -FilePath "choco" -ArgumentList "install $($Program.choco) -y" -Wait -PassThru -RedirectStandardOutput $installOutputFilePath).ExitCode
                if(($chocoInstallStatus -eq 0) -AND (Test-Path -Path $outputFilePath)) {
                    $keywordsFound = Get-Content -Path $outputFilePath | Where {$_ -match "reinstall" -OR $_ -match "already installed"}
		    if ($keywordsFound) {
		        $tryUpgrade = $true
		    }
                }
		# TODO: Implement the Upgrade part using 'choco upgrade' command, this will make choco consistent with WinGet, as WinGet tries to Upgrade when you use the install command.
		if ($tryUpgrade) {
		    throw "Automatic Upgrade for Choco isn't implemented yet, a feature to make it consistent with WinGet, the install command using choco simply failed because $($Program.choco) is already installed."
		}
		if(($chocoInstallStatus -eq 0) -AND ($tryUpgrade -eq $false)){
                    Write-Host "$($Program.choco) installed successfully using Chocolatey."
                    continue
                } else {
                    Write-Host "Failed to install $($Program.choco) using Chocolatey, Chocolatey output:`n`n$(Get-Content -Path $installOutputFilePath)."
                }
            } catch {
                Write-Host "Failed to install $($Program.choco) due to an error: $_"
            }
        }

	if($manage -eq "Uninstalling"){
            write-host "Starting uninstall of $($Program.choco) with Chocolatey."
            try{
		$uninstallOutputFilePath = "$env:TEMP\Install-WinUtilProgramChoco.uninstall-command.output.txt"
		$chocoUninstallStatus = $(Start-Process -FilePath "choco" -ArgumentList "uninstall $($Program.choco) -y" -Wait -PassThru).ExitCode
		if($chocoUninstallStatus -eq 0){
                    Write-Host "$($Program.choco) uninstalled successfully using Chocolatey."
                    continue
                } else {
                    Write-Host "Failed to uninstall $($Program.choco) using Chocolatey, Chocolatey output:`n`n$(Get-Content -Path $uninstallOutputFilePath)."
                }
            } catch {
                Write-Host "Failed to uninstall $($Program.choco) due to an error: $_"
            }
	}
        $x++
    }
    Write-Progress -Activity "$manage Applications" -Status "Finished" -Completed

    # Cleanup leftovers files
    Remove-Item -Path $installOutputFilePath
    Remove-Item -Path $uninstallOutputFilePath

    return;
}
