function Do-PreProcessing {
    param (
        [Parameter(Mandatory, position=0)]
        [string]$ProgressStatusMessage,

        [Parameter(position=1)]
        [string]$ProgressActivity = "Pre-Processing"
    )

    $excludedFiles = @('git\', '.gitignore', '.gitattributes', '.github\CODEOWNERS', 'LICENSE', 'winutil.ps1', 'docs\changelog.md', '*.png', '*.jpg', '*.jpeg', '*.exe')

    $files = Get-ChildItem $workingdir -Recurse -Exclude $excludedFiles -Attributes !Directory
    $numOfFiles = $files.Count

    for ($i = 0; $i -lt $numOfFiles; $i++) {
        $file = $files[$i]
        # TODO:
        #   make more formatting rules, and document them in WinUtil Official Documentation
        (Get-Content -Raw "$file").TrimEnd() `
            -replace ('\t', '    ') `
            -replace ('\)\{', ') {') `
            -replace ('\)\r?\n\s*{', ') {') `
            -replace ('Try \{', 'try {') `
            -replace ('try\{', 'try {') `
            -replace ('try\r?\n\s*\{', 'try {') `
            -replace ('}\r?\n\s*catch', '} catch') `
            -replace ('\} catch', '} catch') `
        | Set-Content "$file"
        Write-Progress -Activity $ProgressActivity -Status "$ProgressStatusMessage - Finished $i out of $numOfFiles" -PercentComplete (($i/$numOfFiles)*100)
    }

    Write-Progress -Activity $ProgressActivity -Status "$ProgressStatusMessage - Finished Task Successfully" -Completed
}
