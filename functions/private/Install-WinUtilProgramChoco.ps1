function Install-WinUtilProgramChoco {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs
    )

    if ($Action -eq 'Install') {
        Start-Process -FilePath choco -ArgumentList "install $Programs -y" -NoNewWindow -Wait
    } else {
        Start-Process -FilePath choco -ArgumentList "uninstall $Programs -y" -NoNewWindow -Wait
    }
}
