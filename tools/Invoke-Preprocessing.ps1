function Invoke-Preprocessing {
    param (
        [Parameter(Mandatory, position=0)]
        [string]$ProgressStatusMessage,

        [Parameter(position=1)]
        [string]$ProgressActivity = "Pre-Processing"
    )

    # We can do Pre-processing on this script file, but by excluding it we're avoiding possible weird behavior,
    # like future runs of this tool being different then previous ones, as the script has modified it self before (one or more times).
    #
    # Note:
    #   There's way too many possible edge cases, not to mention there's no Unit Testing for these tools.. which's a Good Recipe for a Janky/Sensitive Script.
    #   Also, the '.\' isn't necessary, I just like adding them :D (You can remove it, and it should work just fine)
    $excludedFiles = @('.\.git\', '.\.gitignore', '.\.gitattributes', '.\.github\CODEOWNERS', '.\LICENSE', '.\winutil.ps1', '.\tools\Do-PreProcessing.ps1', '.\docs\changelog.md', '*.png', '*.jpg', '*.jpeg', '*.exe')

    $files = Get-ChildItem $sync.PSScriptRoot -Recurse -Exclude $excludedFiles -Attributes !Directory
    $numOfFiles = $files.Count

    for ($i = 0; $i -lt $numOfFiles; $i++) {
        $file = $files[$i]

        # If the file is in Exclude List, don't proceed to check/modify said file.
        $fileIsExcluded = $False
        for ($j = 0; $j -lt $excludedFiles.Count; $j++) {
            $excluded = $excludedFiles[$j]
            $strToCompare = ($excluded) -replace ('^\.\\', '')
            if ($file.FullName.Contains("$strToCompare")) {
                $fileIsExcluded = $True
                break
            }
        }

        if ($fileIsExcluded) {
            continue
        }

        # TODO:
        #   make more formatting rules, and document them in WinUtil Official Documentation
        (Get-Content -Raw "$file").TrimEnd() `
            -replace ('\t', '    ') `
            -replace ('\)\{', ') {') `
            -replace ('\)\r?\n\s*{', ') {') `
            -replace ('Try(\s*)?\{', 'try {') `
            -replace ('try\r?\n\s*\{', 'try {') `
            -replace ('}\r?\n\s*catch', '} catch') `
            -replace ('\}(\s*)?Catch', '} catch') `
        | Set-Content "$file"
        Write-Progress -Activity $ProgressActivity -Status "$ProgressStatusMessage - Finished $i out of $numOfFiles" -PercentComplete (($i/$numOfFiles)*100)
    }

    Write-Progress -Activity $ProgressActivity -Status "$ProgressStatusMessage - Finished Task Successfully" -Completed
}
