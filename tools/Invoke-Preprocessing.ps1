function Invoke-Preprocessing {
    <#
        .SYNOPSIS
        A function that does Code Formatting using RegEx, useful when trying to force specific coding standard(s) to a project.

        .PARAMETER ThrowExceptionOnEmptyFilesList
        A switch which'll throw an exception upon not finding any files inside the provided 'WorkingDir'.

        .PARAMETER SkipExcludedFilesValidation
        A switch to stop file path validation on 'ExcludedFiles' list.

        .PARAMETER ExcludedFiles
        A list of file paths which're *relative to* 'WorkingDir' Folder, every item in the list can be pointing to File (doesn't end with '\') or Directory (ends with '\') or None-Existing File/Directory.
        By default, it checks if everyitem exists, and throws an exception if one or more are not found (None-Existing), if you want to skip this validation, please consider providing the '-SkipExcludedFilesValidation' switch to skip this check.

        .PARAMETER WorkingDir
        The folder to search inside recursively for files which're going to be Preprocessed (Code Formatted), unless they're found in 'ExcludedFiles' List.
        Note: The path should be absolute, NOT relative.

        .PARAMETER ProgressStatusMessage
        The status message used when displaying the progress bar, which's done through PowerShell 'Write-Progress' Cmdlet.
        This's a Required Parameter, as the information displayed to terminal is useful when running this function,
        which might take less than 1 sec to minutes depending on project's scale & hardware performance.

        .PARAMETER ProgressActivity
        The activity message used when displaying the progress bar, which's done through PowerShell 'Write-Progress' Cmdlet,
        This's an Optional Parameter, default value is 'Preprocessing', used in combination with 'ProgressStatusMessage' Parameter Value.

        .EXAMPLE
        Invoke-Preprocessing -WorkingDir "DRIVE:\Path\To\Folder\" -ExcludedFiles @('file.txt', '.\.git\', '*.png') -ProgressStatusMessage "Doing Preprocessing"

        Calls 'Invoke-Preprocessing' function using Named Paramters, with 'WorkingDir' (Mandatory Parameter) which's used as the base folder when searching for files recursively (using 'Get-ChildItem'), other two paramters are, in order from right to left, the Optional 'ExcludeFiles', which can be a path to a file, folder, or pattern-matched (like '*.png'), and the 'ProgressStatusMessage', which's used in Progress Bar.

        .EXAMPLE
        Invoke-Preprocessing -WorkingDir "DRIVE:\Path\To\Folder\" -ExcludedFiles @('file.txt', '.\.git\', '*.png') -ProgressStatusMessage "Doing Preprocessing" -ProgressActivity "Re-Formatting Code"

        Same as Example No. 1, but uses 'ProgressActivity' which's used in Progress Bar.

        .EXAMPLE
        Invoke-Preprocessing -ThrowExceptionOnEmptyFilesList -WorkingDir "DRIVE:\Path\To\Folder\" -ExcludedFiles @('file.txt', '.\.git\', '*.png') -ProgressStatusMessage "Doing Preprocessing"

        Same as Example No. 1, but uses '-ThrowExceptionOnEmptyFilesList', which's an optional parameter that'll make 'Invoke-Preprocessing' throw an exception when no files are found in 'WorkingDir' (not including the ExcludedFiles, of course), useful when you want to double check your parameters & you're sure there's files to process in the 'WorkingDir'.

        .EXAMPLE
        Invoke-Preprocessing -Skip -WorkingDir "DRIVE:\Path\To\Folder\" -ExcludedFiles @('file.txt', '.\.git\', '*.png') -ProgressStatusMessage "Doing Preprocessing"

        Same as Example No. 1, but uses '-SkipExcludedFilesValidation', which'll skip the validation step for 'ExcludedFiles' list. This can be useful when 'ExcludedFiles' list is generated from another function, or from unreliable source (you can't guarantee every item in list is a valid path), but you want to silently continue through the function.
    #>

    param (
        [Parameter(position=0)]
        [switch]$SkipExcludedFilesValidation,

        [Parameter(position=1)]
        [switch]$ThrowExceptionOnEmptyFilesList,

        [Parameter(Mandatory, position=2)]
        [ValidateScript({[System.IO.Path]::IsPathRooted($_)})]
        [string]$WorkingDir,

        [Parameter(position=3)]
        [string[]]$ExcludedFiles,

        [Parameter(Mandatory, position=4)]
        [string]$ProgressStatusMessage,

        [Parameter(position=5)]
        [string]$ProgressActivity = "Preprocessing"
    )

    if (-NOT (Test-Path -PathType Container -Path "$WorkingDir")) {
        throw "[Invoke-Preprocessing] Invalid Paramter Value for 'WorkingDir', passed value: '$WorkingDir'. Either the path is a File or Non-Existing/Invlid, please double check your code."
    }

    $count = $ExcludedFiles.Count

    # Make sure there's a * at the end of folders in ExcludedFiles list
    for ($i = 0; $i -lt $count; $i++) {
        $excludedFile = $ExcludedFiles[$i]
        $isFolder = ($excludedFile) -match '\\$'
        if ($isFolder) { $ExcludedFiles[$i] = $excludedFile + '*' }
    }

    # Validate the ExcludedFiles List before continuing on,
    # that's if there's a list in the first place, and '-SkipExcludedFilesValidation' was not provided.
    if (-not $SkipExcludedFilesValidation) {
        for ($i = 0; $i -lt $count; $i++) {
            $excludedFile = $ExcludedFiles[$i]
            $filePath = "$(($WorkingDir -replace ('\\$', '')) + '\' + ($excludedFile -replace ('\.\\', '')))"

            # Handle paths with wildcards in a different implementation
            $matches = ($filePath) -match '^.*?\*'

            if ($matches) {
                if (-NOT (Get-ChildItem -Recurse -Path "$filePath" -File -Force)) {
                    $failedFilesList += "'$filePath', "
                }
            } else {
                if (-NOT (Test-Path -Path "$filePath")) {
                    $failedFilesList += "'$filePath', "
                }
            }
        }
        $failedFilesList = $failedFilesList -replace (',\s*$', '')
        if (-NOT $failedFilesList -eq "") {
            throw "[Invoke-Preprocessing] One or more File Paths and/or File Patterns were not found, you can use '-SkipExcludedFilesValidation' switch to skip this check, the failed to validate are: $failedFilesList"
        }
    }

    # Get Files List
    [System.Collections.ArrayList]$files = Get-ChildItem $WorkingDir -Recurse -Exclude $ExcludedFiles -File -Force
    $numOfFiles = $files.Count

    # Only keep the 'FullName' Property for every entry in the list
    for ($i = 0; $i -lt $numOfFiles; $i++) {
        $file = $files[$i]
        $files[$i] = $file.FullName
    }

    # If a file(s) are found in Exclude List,
    # Remove the file from files list.
    for ($j = 0; $j -lt $excludedFiles.Count; $j++) {
        # Prepare some variables
        $excluded = $excludedFiles[$j]
        $pathToFind = ($excluded) -replace ('^\.\\', '')
        $pathToFind = $WorkingDir + '\' + $pathToFind
        $index = -1 # reset index on every iteration

        # Handle paths with wildcards in a different implementation
        $matches = ($pathToFind) -match '^.*?\*'

        if ($matches) {
             $filesToCheck = Get-ChildItem -Recurse -Path "$pathToFind" -File -Force
             if ($filesToCheck) {
                for ($k = 0; $k -lt $filesToCheck.Count; $k++) {
                    $fileToCheck = $filesToCheck[$k]
                    $index = $files.IndexOf("$fileToCheck")
                    if ($index -ge 0) { $files.RemoveAt($index) }
                }
             }
        } else {
            $index = $files.IndexOf("$pathToFind")
            if ($index -ge 0) { $files.RemoveAt($index) }
        }
    }

    # Make sure 'numOfFiles' is synced with the actual Number of Files found in '$files'
    # This's done because previous may or may not edit the files list, so we should update it
    $numOfFiles = $files.Count

    if ($numOfFiles -eq 0) {
        if ($ThrowExceptionOnEmptyFilesList) {
            throw "[Invoke-Preprocessing] Found 0 Files to Preprocess inside 'WorkingDir' Directory and '-ThrowExceptionOnEmptyFilesList' Switch is provided, value of 'WorkingDir': '$WorkingDir'."
        } else {
            return # Do an early return, there's nothing else to do
        }
    }

    for ($i = 0; $i -lt $numOfFiles; $i++) {
        $fullFileName = $files[$i]

        # TODO:
        #   make more formatting rules, and document them in WinUtil Official Documentation
        (Get-Content "$fullFileName").TrimEnd() `
            -replace ('\t', '    ') `
            -replace ('\)\s*\{', ') {') `
            -replace ('(?<keyword>if|for|foreach)\s*(?<condition>\([.*?]\))\s*\{', '${keyword} ${condition} {') `
            -replace ('\}\s*elseif\s*(?<condition>\([.*?]\))\s*\{', '} elseif ${condition} {') `
            -replace ('\}\s*else\s*\{', '} else {') `
            -replace ('Try\s*\{', 'try {') `
            -replace ('Catch\s*\{', 'catch {') `
            -replace ('\}\s*Catch', '} catch') `
            -replace ('\}\s*Catch\s*(?<exceptions>(\[.*?\]\s*(\,)?\s*)+)\s*\{', '} catch ${exceptions} {') `
            -replace ('\}\s*Catch\s*(?<exceptions>\[.*?\])\s*\{', '} catch ${exceptions} {') `
            -replace ('(?<parameter_type>\[[^$0-9]+\])\s*(?<str_after_type>\$.*?)', '${parameter_type}${str_after_type}') `
        | Set-Content "$fullFileName"

        Write-Progress -Activity $ProgressActivity -Status "$ProgressStatusMessage - Finished $i out of $numOfFiles" -PercentComplete (($i/$numOfFiles)*100)
    }

    Write-Progress -Activity $ProgressActivity -Status "$ProgressStatusMessage - Finished Task Successfully" -Completed
}
