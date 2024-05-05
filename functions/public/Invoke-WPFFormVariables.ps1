Function Invoke-WPFFormVariables {
    <#

    .SYNOPSIS
        Prints the logo

    #>
    #If ($global:ReadmeDisplay -ne $true) { Write-Host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow; $global:ReadmeDisplay = $true }


    Write-Host ""
    Write-Host " __        ___       _   _ _   _ _                               "
    Write-Host " \ \      / (_)_ __ | | | | |_(_) |                              "
    Write-Host "  \ \ /\ / /| | '_ \| | | | __| | |                              "
    Write-Host "   \ V  V / | | | | | |_| | |_| | |                              "
    Write-Host " __ \_/\_/ _|_|_| |_|\___/ \__|_|_|                              "
    Write-Host " \ \      / /__ _ __| | ___ __ ___   __ _ _ __   __  ___   _ ____"
    Write-Host "  \ \ /\ / / _ \ '__| |/ / '_ ` _ \ / _` | '_ \  \ \/ / | | |_  /"
    Write-Host "   \ V  V /  __/ |  |   <| | | | | | (_| | | | |_ >  <| |_| |/ / "
    Write-Host "    \_/\_/ \___|_|  |_|\_\_| |_| |_|\__,_|_| |_(_)_/\_\\__, /___|"
    Write-Host "                                                       |___/     "
    Write-Host ""
    Write-Host "====Werkman.xyz====="
    Write-Host "=====Windows Toolbox====="

    #====DEBUG GUI Elements====

    #Write-Host "Found the following interactable elements from our form" -ForegroundColor Cyan
    #get-variable WPF*
}
