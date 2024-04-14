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
            # Install package via ID, if it fails try again with different scope. 
            # Install-WinGetPackage always returns "InstallerErrorCode" 0, so we have to check the "Status" of the install.
            $status=$((Install-WinGetPackage -Id $Program -Scope SystemOrUnknown -Mode Silent -AcceptPackageAgreement -AcceptSourceAgreement).Status)
            if($status -ne "Ok"){
                $status=$((Install-WinGetPackage -Id $Program -Scope UserOrUnknown -Mode Silent -AcceptPackageAgreement -AcceptSourceAgreement).Status)
                if($status -ne "Ok"){
                    $status=$((Install-WinGetPackage -Id $Program -Scope Any -Mode Silent -AcceptPackageAgreement -AcceptSourceAgreement).Status)
                    if($status -ne "Ok"){
                        Write-Host "Failed to install $Program."
                    } else {
                        Write-Host "$Program installed successfully."
                    }
                } else {
                    Write-Host "$Program installed successfully."
                }
            } else {
                Write-Host "$Program installed successfully."
            }
        }
        if($manage -eq "Uninstalling"){
            # Uninstall package via ID.
            # Uninstall-WinGetPackage always returns "InstallerErrorCode" 0, so we have to check the "Status" of the uninstall.
            $status=$((Uninstall-WinGetPackage -Id $Program -Mode Silent -AcceptSourceAgreement).Status)
            if ("$status" -ne "Ok") {
                Write-Host "Failed to uninstall $Program."
            } else {
                Write-Host "$Program uninstalled successfully."
            }
	    }
        $X++
    }

    Write-Progress -Activity "$manage Applications" -Status "Finished" -Completed
}