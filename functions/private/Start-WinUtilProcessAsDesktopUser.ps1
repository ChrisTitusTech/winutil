function Start-WinUtilProcessAsDesktopUser {
    param(
        [Parameter(Mandatory = $true)]
        [string] $FilePath
    )

    $shell = New-Object -ComObject Shell.Application
    $workingDirectory = Split-Path -Path $FilePath -Parent

    $shell.ShellExecute(
        $FilePath,
        "",
        $workingDirectory,
        "open",
        1
    )
}
