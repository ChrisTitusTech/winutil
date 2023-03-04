Function Install-WinUtilProgramWinget {

    <#
    
        .DESCRIPTION
        This will install programs via Winget using a new powershell.exe instance to prevent the GUI from locking up.

        Note the triple quotes are required any time you need a " in a normal script block.
    
    #>

    param($ProgramsToInstall)

    $x = 0
    $count = $($ProgramsToInstall -split ",").Count

    Write-Progress -Activity "Installing Applications" -Status "Starting" -PercentComplete 0

    Foreach ($Program in $($ProgramsToInstall -split ",")){
    
        Write-Progress -Activity "Installing Applications" -Status "Installing $Program $($x + 1) of $count" -PercentComplete $($x/$count*100)
        Start-Process -FilePath winget -ArgumentList "install -e --accept-source-agreements --accept-package-agreements --silent $Program" -NoNewWindow -Wait;
        $X++
    }

    Write-Progress -Activity "Installing Applications" -Status "Finished" -Completed

}
