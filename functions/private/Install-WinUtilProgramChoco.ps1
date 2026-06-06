function Install-WinUtilProgramChoco {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Install", "Uninstall")]
        [string]$Action,

        [Parameter(Mandatory=$true)]
        [string[]]$Programs
    )

    if ($Action -eq 'Install') {
        $chocoArgs = @('install') + $Programs + @('-y')
        Start-Process -FilePath choco -ArgumentList $chocoArgs -NoNewWindow -Wait
    } else {
        $chocoArgs = @('uninstall') + $Programs + @('-y')
        Start-Process -FilePath choco -ArgumentList $chocoArgs -NoNewWindow -Wait
    }
}