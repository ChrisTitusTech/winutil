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
                $chocoStatus = $(Start-Process -FilePath "choco" -ArgumentList "install $($Program.choco) -y" -Wait -PassThru).ExitCode
                if($chocoStatus -eq 0){
                    Write-Host "$($Program.choco) installed successfully using Chocolatey."
                    continue
                } else {
                    Write-Host "Failed to install $($Program.choco) using Chocolatey."
                }
                Write-Host "Failed to install $($Program.choco)."
            } catch {
                Write-Host "Failed to install $($Program.choco) due to an error: $_"
            }
        }
        if($manage -eq "Uninstalling"){
            throw "not yet implemented";
        }
        $X++
    }
    Write-Progress -Activity "$manage Applications" -Status "Finished" -Completed
    return;
}
