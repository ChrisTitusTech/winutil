Function Update-WinUtilProgramWinget {
    Start-Process -FilePath winget.exe -ArgumentList 'upgrade --all --silent --include-unknown --accept-source-agreements --accept-package-agreements' -Wait -NoNewWindow
}
