function Invoke-WinUtilUninstallPSProfile {
    if (Test-Path ($Profile + '.bak')) {
        Rename-Item ($Profile + '.bak') -NewName $Profile
    }
    else {
        Remove-Item $Profile
    }
}
