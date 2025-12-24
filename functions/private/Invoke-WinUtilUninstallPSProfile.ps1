function Invoke-WinUtilUninstallPSProfile {
    if (Test-Path ($Profile + '.bak')) {
        Remove-Item $Profile
        Rename-Item ($Profile + '.bak') -NewName $Profile
    }
    else {
        Remove-Item $Profile
    }
}
