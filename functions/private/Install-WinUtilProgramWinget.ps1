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
            # --scope=machine when installing non-UWP apps with winget fails with error code 0x80070005.
            # Removed argument while testing new Winget install method.
            # Open issue on winget-cli github repo: https://github.com/microsoft/winget-cli/issues/3936
            Start-Process -FilePath winget -ArgumentList "install -e --accept-source-agreements --accept-package-agreements --silent $Program" -NoNewWindow -Wait
        }
        if($manage -eq "Uninstalling"){
        Start-Process -FilePath winget -ArgumentList "uninstall -e --accept-source-agreements --purge --force --silent $Program" -NoNewWindow -Wait
	}

        $X++
    }

    Write-Progress -Activity "$manage Applications" -Status "Finished" -Completed

}
