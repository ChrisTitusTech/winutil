Function Install-WinUtilProgramWinget {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs
    )

    if ($Action -eq 'Install') {
        Start-Process -FilePath winget -ArgumentList "install $Programs --accept-package-agreements --source winget --silent" -NoNewWindow -Wait
    } else {
        Start-Process -FilePath winget -ArgumentList "uninstall $Programs --source winget --silent" -NoNewWindow -Wait
    }
}
