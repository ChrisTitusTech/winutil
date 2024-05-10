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
    #>

    param(
        $ProgramsToInstall,
        $manage = "Installing"
    )

    $x = 0
    $count = $($ProgramsToInstall -split ",").Count

    Write-Progress -Activity "$manage Applications" -Status "Starting" -PercentComplete 0

    Foreach ($Program in $($ProgramsToInstall -split ",")){

        Write-Progress -Activity "$manage Applications" -Status "$manage $Program $($x + 1) of $count" -PercentComplete $($x/$count*100)
        if($manage -eq "Installing"){
            # Install package via ID, if it fails try again with different scope and then with an unelevated prompt. 
            # Since Install-WinGetPackage might not be directly available, we use winget install command as a workaround.
            # Winget, not all installers honor any of the following: System-wide, User Installs, or Unelevated Prompt OR Silent Install Mode.
            # This is up to the individual package maintainers to enable these options. Aka. not as clean as Linux Package Managers.
            try {
                $status = $(Start-Process -FilePath "winget" -ArgumentList "install --id $Program --silent --accept-source-agreements --accept-package-agreements" -Wait -PassThru).ExitCode
                if($status -eq 0){
                    Write-Host "$Program installed successfully."
                    continue
                }
                Write-Host "Attempt with User scope"
                $status = $(Start-Process -FilePath "winget" -ArgumentList "install --id $Program --scope user --silent --accept-source-agreements --accept-package-agreements" -Wait -PassThru).ExitCode
                if($status -eq 0){
                    Write-Host "$Program installed successfully with User scope."
                    continue
                }
                Write-Host "Attempt with User prompt"
                $userChoice = [System.Windows.MessageBox]::Show("Do you want to attempt $Program installation with specific user credentials? Select 'Yes' to proceed or 'No' to skip.", "User Credential Prompt", [System.Windows.MessageBoxButton]::YesNo)
                if ($userChoice -eq 'Yes') {
                    $getcreds = Get-Credential
                    $process = Start-Process -FilePath "winget" -ArgumentList "install --id $Program --silent --accept-source-agreements --accept-package-agreements" -Credential $getcreds -PassThru
                    Wait-Process -Id $process.Id
                    $status = $process.ExitCode
                } else {
                    Write-Host "Skipping installation with specific user credentials."
                }
                if($status -eq 0){
                    Write-Host "$Program installed successfully with User prompt."
                    continue
                }
                Write-Host "Attempting installation with Chocolatey as a fallback method"
                $status = $(Start-Process -FilePath "choco" -ArgumentList "install $Program -y" -Wait -PassThru).ExitCode
                if($status -eq 0){
                    Write-Host "$Program installed successfully using Chocolatey."
                    continue
                }
                Write-Host "Failed to install $Program. You need to install it manually... Sorry!"
    } catch {
                Write-Host "Failed to install $Program due to an error: $_"
                }
        }
        if($manage -eq "Uninstalling"){
            # Uninstall package via ID using winget directly.
            try {
                $status = $(Start-Process -FilePath "winget" -ArgumentList "uninstall --id $Program --silent" -Wait -PassThru).ExitCode
                if($status -ne 0){
                    Write-Host "Failed to uninstall $Program."
                } else {
                    Write-Host "$Program uninstalled successfully."
                }
            } catch {
                Write-Host "Failed to uninstall $Program due to an error: $_"
            }
        }
        $X++
    }

    Write-Progress -Activity "$manage Applications" -Status "Finished" -Completed
}
