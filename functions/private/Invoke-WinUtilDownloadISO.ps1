function Invoke-WinUtilDownloadISO {
    param(
        $rel,
        $locale,
        $arch
    )
    # Download Windows 11 ISO
    # Credit: https://github.com/pbatard/Fido

    $fidopath = "$env:temp\fido.ps1"

    Invoke-Webrequest "https://github.com/pbatard/Fido/raw/master/Fido.ps1" -OutFile $fidopath

    & $fidopath -Win "Windows 11" -Rel $rel -Locale $locale -Arch $arch

    return "$workingdir\*.iso"
}