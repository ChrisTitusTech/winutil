Function Install-ProgramWinget {

    <#
    
        .DESCRIPTION
        This will install programs via Winget using a new powershell.exe instance to prevent the GUI from locking up.

        Note the triple quotes are required any time you need a " in a normal script block.
    
    #>

    param($ProgramsToInstall)

    [ScriptBlock]$wingetinstall = {
        param($ProgramsToInstall)

        $host.ui.RawUI.WindowTitle = """Winget Install"""

        $x = 0
        $count = $($ProgramsToInstall -split """,""").Count

        Write-Progress -Activity """Installing Applications""" -Status """Starting""" -PercentComplete 0
    
        Write-Host """`n`n`n`n`n`n"""
        
        Start-Transcript $ENV:TEMP\winget.log -Append
    
        Foreach ($Program in $($ProgramsToInstall -split """,""")){
    
            Write-Progress -Activity """Installing Applications""" -Status """Installing $Program $($x + 1) of $count""" -PercentComplete $($x/$count*100)
            Start-Process -FilePath winget -ArgumentList """install -e --accept-source-agreements --accept-package-agreements --silent $Program""" -NoNewWindow -Wait;
            $X++
        }

        Write-Progress -Activity """Installing Applications""" -Status """Finished""" -Completed
        Write-Host """`n`nAll Programs have been installed"""
        Pause
    }

    $global:WinGetInstall = Start-Process -Verb runas powershell -ArgumentList "-command invoke-command -scriptblock {$wingetinstall} -argumentlist '$($ProgramsToInstall -join ",")'" -PassThru

}
