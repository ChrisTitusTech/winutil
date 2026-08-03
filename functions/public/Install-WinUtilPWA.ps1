function Install-WinUtilPWA {
    param(
        [Parameter(Mandatory)]
        $Programs
    )

    $EdgePath = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"

    if (!(Test-Path $EdgePath)) {
        $EdgePath = "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe"
    }

    if (!(Test-Path $EdgePath)) {
        Write-WinUtilLog -Level "ERROR" -Component "PWA" -Message "Microsoft Edge not found."
        return
    }


    foreach ($program in $Programs) {

    Write-WinUtilLog `
        -Component "PWA" `
        -Message "Installing PWA: content=$($program.content), url=$($program.pwa)"

    $arguments = @(
        "--app=$($program.pwa)"
        "--no-first-run"
    )

    New-WinUtilPWAShortcut `
    -Name $program.content `
    -Url $program.pwa `
    -EdgePath $EdgePath
    Start-Process `
        -FilePath $EdgePath `
        -ArgumentList $arguments `
        -Wait
    }
}
function New-WinUtilPWAShortcut {

    param(
        $Name,
        $Url,
        $EdgePath
    )


    $ShortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\$Name.lnk"


    $WshShell = New-Object -ComObject WScript.Shell

    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)

    $Shortcut.TargetPath = $EdgePath

    $Shortcut.Arguments = "--app=$Url"

    $Shortcut.WorkingDirectory = Split-Path $EdgePath

    $Shortcut.Save()
}