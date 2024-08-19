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

        Same as Example No. 1, but will throw an exception when 'Invoke-Preprocessing' function doesn't find any files in 'WorkingDir' (not including 'ExcludedFiles' list).

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
    if ((-NOT ($count -eq 0)) -AND (-NOT $SkipExcludedFilesValidation)) {
        for ($i = 0; $i -lt $count; $i++) {
            $excludedFile = $ExcludedFiles[$i]
            $filePath = "$(($WorkingDir -replace ('\\$', '')) + '\' + ($excludedFile -replace ('\.\\', '')))"
            if (-NOT (Get-ChildItem -Recurse -Path "$filePath" -File)) {
                $failedFilesList += "'$filePath', "
            }
        }
        $failedFilesList = $failedFilesList -replace (',\s*$', '')
        if (-NOT $failedFilesList -eq "") {
            throw "[Invoke-Preprocessing] One or more File Paths & File Patterns were not found, you can use '-SkipExcludedFilesValidation' switch to skip this check, and the failed files are: $failedFilesList"
        }
    }

    $files = Get-ChildItem $WorkingDir -Recurse -Exclude $ExcludedFiles -File
    $numOfFiles = $files.Count

    if ($numOfFiles -eq 0) {
        if ($ThrowExceptionOnEmptyFilesList) {
            throw "[Invoke-Preprocessing] Found 0 Files to Preprocess inside 'WorkingDir' Directory and '-ThrowExceptionOnEmptyFilesList' Switch is provided, value of 'WorkingDir': '$WorkingDir'."
        } else {
            return # Do an early return, there's nothing else to do
        }
    }

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
        (Get-Content "$file").TrimEnd() `
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
            -replace ('(?<parameter_type>\[.*?\])\s*(?<str_after_type>\$.*?(,|\s*\)))', '${parameter_type}${str_after_type}') `
        | Set-Content "$file"

        Write-Progress -Activity $ProgressActivity -Status "$ProgressStatusMessage - Finished $i out of $numOfFiles" -PercentComplete (($i/$numOfFiles)*100)
    }

    Write-Progress -Activity $ProgressActivity -Status "$ProgressStatusMessage - Finished Task Successfully" -Completed
}
