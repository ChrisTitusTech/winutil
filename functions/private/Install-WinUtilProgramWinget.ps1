Function Install-WinUtilProgramWinget {
    
    <#
    .SYNOPSIS
    Manages the provided programs using Winget
    
    .PARAMETER ProgramsToInstall
    A list of programs to manage
    
    .PARAMETER manage
    The action to perform on the programs, can be either 'Installing' or 'Uninstalling'
    
    .NOTES
    The triple quotes are required any time you need a " in a normal script block.
    The winget Return codes are documented here: https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-manager/winget/returnCodes.md
    #>
    
    param(
        [Parameter(Mandatory, Position=0)]
        [PsCustomObject]$ProgramsToInstall,
    
        [Parameter(Position=1)]
        [String]$manage = "Installing"
    )
    $x = 0
    $count = $ProgramsToInstall.Count
    
    Write-Progress -Activity "$manage Applications" -Status "Starting" -PercentComplete 0
    Write-Host "==========================================="
    Write-Host "--    Configuring winget packages       ---"
    Write-Host "==========================================="
    Foreach ($Program in $ProgramsToInstall){
        $failedPackages = @()
        Write-Progress -Activity "$manage Applications" -Status "$manage $($Program.winget) $($x + 1) of $count" -PercentComplete $($x/$count*100)
        if($manage -eq "Installing"){
            # Install package via ID, if it fails try again with different scope and then with an unelevated prompt. 
            # Since Install-WinGetPackage might not be directly available, we use winget install command as a workaround.
            # Winget, not all installers honor any of the following: System-wide, User Installs, or Unelevated Prompt OR Silent Install Mode.
            # This is up to the individual package maintainers to enable these options. Aka. not as clean as Linux Package Managers.
            Write-Host "Starting install of $($Program.winget) with winget."
            try {
                $status = $(Start-Process -FilePath "winget" -ArgumentList "install --id $($Program.winget) --silent --accept-source-agreements --accept-package-agreements" -Wait -PassThru -NoNewWindow).ExitCode
                if($status -eq 0){
                    Write-Host "$($Program.winget) installed successfully."
                    continue
                }
                if ($status -eq  -1978335189){
                    Write-Host "$($Program.winget) No applicable update found"
                    continue
                }
                Write-Host "Attempt with User scope"
                $status = $(Start-Process -FilePath "winget" -ArgumentList "install --id $($Program.winget) --scope user --silent --accept-source-agreements --accept-package-agreements" -Wait -PassThru -NoNewWindow).ExitCode
                if($status -eq 0){
                    Write-Host "$($Program.winget) installed successfully with User scope."
                    continue
                }
                if ($status -eq  -1978335189){
                    Write-Host "$($Program.winget) No applicable update found"
                    continue
                }
                Write-Host "Attempt with User prompt"
                $userChoice = [System.Windows.MessageBox]::Show("Do you want to attempt $($Program.winget) installation with specific user credentials? Select 'Yes' to proceed or 'No' to skip.", "User Credential Prompt", [System.Windows.MessageBoxButton]::YesNo)
                if ($userChoice -eq 'Yes') {
                    $getcreds = Get-Credential
                    $process = Start-Process -FilePath "winget" -ArgumentList "install --id $($Program.winget) --silent --accept-source-agreements --accept-package-agreements" -Credential $getcreds -PassThru -NoNewWindow
                    Wait-Process -Id $process.Id
                    $status = $process.ExitCode
                } else {
                    Write-Host "Skipping installation with specific user credentials."
                }
                if($status -eq 0){
                    Write-Host "$($Program.winget) installed successfully with User prompt."
                    continue
                }
                if ($status -eq  -1978335189){
                    Write-Host "$($Program.winget) No applicable update found"
                    continue
                }
            } catch {
                Write-Host "Failed to install $($Program.winget). With winget"
                $failedPackages += $Program
            }
        }
        if($manage -eq "Uninstalling"){
            # Uninstall package via ID using winget directly.
            try {
                $status = $(Start-Process -FilePath "winget" -ArgumentList "uninstall --id $($Program.winget) --silent" -Wait -PassThru -NoNewWindow).ExitCode
                if($status -ne 0){
                    Write-Host "Failed to uninstall $($Program.winget)."
                } else {
                    Write-Host "$($Program.winget) uninstalled successfully."
                    $failedPackages += $Program
                }
            } catch {
                Write-Host "Failed to uninstall $($Program.winget) due to an error: $_"
                $failedPackages += $Program
            }
        }
        $X++
    }
    Write-Progress -Activity "$manage Applications" -Status "Finished" -Completed
    return $failedPackages;
}
