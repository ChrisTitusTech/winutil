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
        [Parameter(Mandatory, Position = 0)]
        [PsCustomObject]$ProgramsToInstall,

        [Parameter(Position = 1)]
        [String]$manage = "Installing"
    )

    $x = 0
    $count = $ProgramsToInstall.Count

    # This check isn't really necessary, as there's a couple of checks before this Private Function gets called, but just to make sure ;)
    if ($count -le 0) {
        throw "Private Function 'Install-WinUtilProgramChoco' expected Parameter 'ProgramsToInstall' to be of size 1 or greater, instead got $count,`nPlease double check your code and re-compile WinUtil."
    }


    Write-Host "==========================================="
    Write-Host "--   Configuring Chocolatey pacakages   ---"
    Write-Host "==========================================="
    Foreach ($Program in $ProgramsToInstall) {

        if ($manage -eq "Installing") {
            write-host "Starting install of $($Program.choco) with Chocolatey."
            try {
                $tryUpgrade = $false
                $installOutputFilePath = "$env:TEMP\Install-WinUtilProgramChoco.install-command.output.txt"
                New-Item -ItemType File -Path $installOutputFilePath
                $chocoInstallStatus = $(Start-Process -FilePath "choco" -ArgumentList "install $($Program.choco) -y --log-file $($installOutputFilePath)" -Wait -PassThru).ExitCode
                if (($chocoInstallStatus -eq 0) -AND (Test-Path -Path $installOutputFilePath)) {
                    $keywordsFound = Get-Content -Path $installOutputFilePath | Where-Object { $_ -match "reinstall" -OR $_ -match "already installed" }
                    if ($keywordsFound) {
                        $tryUpgrade = $true
                    }
                }
                if ($tryUpgrade) {
                    $chocoUpdateStatus = $(Start-Process -FilePath "choco" -ArgumentList "upgrade $($Program.choco) -y" -Wait -PassThru).ExitCode
                    if ($chocoUpdateStatus -eq 0) {
                        Write-Host "$($Program.choco) was updated successfully using Chocolatey."
                    }
                    else{
                        Write-Host "Failed upgdate of $($Program.choco) using Chocolatey."
                    }
                }
                if (($chocoInstallStatus -eq 0) -AND ($tryUpgrade -eq $false)) {
                    Write-Host "$($Program.choco) installed successfully using Chocolatey."
                    $X++
                    $sync.form.Dispatcher.Invoke([action] { Set-WinUtilTaskbaritem -state "Normal" -value ($x / $count) })
                    continue
                }
                elseif (($chocoInstallStatus -ne 0) -AND ($tryUpgrade -eq $false)) {
                    Write-Host "Failed to install $($Program.choco) using Chocolatey"
                    $X++
                    $sync.form.Dispatcher.Invoke([action] { Set-WinUtilTaskbaritem -state "Error" -value ($x / $count) })
                }
            }
            catch {
                Write-Host "Failed to install $($Program.choco) due to an error: $_"
                $X++
                $sync.form.Dispatcher.Invoke([action] { Set-WinUtilTaskbaritem -state "Error" -value ($x / $count) })
            }
        }

        if ($manage -eq "Uninstalling") {
            Write-Host "Searching for Metapackages of of $($Program.choco) (.install or .portable)"
            $chocoPackages = ((choco list | Select-String -Pattern "$($Program.choco)(\.install|\.portable) {0,1}").Matches.Value) -join " "
            Write-Host "Starting uninstall of $chocoPackages with Chocolatey."
            try {
                $uninstallOutputFilePath = "$env:TEMP\Install-WinUtilProgramChoco.uninstall-command.output.txt"
                New-Item -ItemType File -Path $uninstallOutputFilePath
                $chocoUninstallStatus = $(Start-Process -FilePath "choco" -ArgumentList "uninstall $chocoPackages -y" -Wait -PassThru).ExitCode
                if ($chocoUninstallStatus -eq 0) {
                    Write-Host "$($Program.choco) uninstalled successfully using Chocolatey."
                    $x++
                    $sync.form.Dispatcher.Invoke([action] { Set-WinUtilTaskbaritem -state "Normal" -value ($x / $count) })
                    continue
                }
                else {
                    Write-Host "Failed to uninstall $($Program.choco) using Chocolatey, Chocolatey output:`n`n$(Get-Content -Path $uninstallOutputFilePath)."
                    $x++
                    $sync.form.Dispatcher.Invoke([action] { Set-WinUtilTaskbaritem -state "Error" -value ($x / $count) })
                }
            }
            catch {
                Write-Host "Failed to uninstall $($Program.choco) due to an error: $_"
                $x++
                $sync.form.Dispatcher.Invoke([action] { Set-WinUtilTaskbaritem -state "Error" -value ($x / $count) })
            }
        }
    }

    # Cleanup leftovers files
    if (Test-Path -Path $installOutputFilePath) { Remove-Item -Path $installOutputFilePath }
    if (Test-Path -Path $uninstallOutputFilePath) { Remove-Item -Path $uninstallOutputFilePath }

    return;
}
