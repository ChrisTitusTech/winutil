Function Install-WinUtilProgramWinget {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs
    )

    if ($Action -eq 'Install') {
        $wingetArgs = @('install') + $Programs + @('--accept-package-agreements', '--source', 'winget', '--silent')
        Start-Process -FilePath winget -ArgumentList $wingetArgs -NoNewWindow -Wait
    } else {
        $wingetArgs = @('uninstall') + $Programs + @('--source', 'winget', '--silent')
        Start-Process -FilePath winget -ArgumentList $wingetArgs -NoNewWindow -Wait
    }
}