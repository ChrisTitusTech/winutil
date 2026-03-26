Function Update-WinUtilProgramWinget {

    <#

    .SYNOPSIS
        This will update all programs using WinGet

    #>

    [ScriptBlock]$wingetinstall = {

        $host.ui.RawUI.WindowTitle = """WinGet Install"""

        Start-Transcript "$logdir\winget-update_$dateTime.log" -Append
        winget upgrade --all --accept-source-agreements --accept-package-agreements --scope=machine --silent

    }

    $global:WinGetInstall = Start-Process -Verb runas powershell -ArgumentList "-command invoke-command -scriptblock {$wingetinstall} -argumentlist '$($ProgramsToInstall -join ",")'" -PassThru

}
