function Invoke-Preprocessing {
    <#
        .SYNOPSIS
        A function that does Code Formatting using RegEx, useful when trying to force specific coding standard(s) to a project.

        .PARAMETER ExcludedFiles
        A list of file paths which're *relative to* 'WorkingDir' Folder, every item in the list can be pointing to File (doesn't end with '\') or Directory (ends with '\') or None-Existing File/Directory.
        By default, it checks if everyitem exists, and throws an exception if one or more are not found (None-Existing).

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

        Calls 'Invoke-Preprocessing' function using Named Parameters, with 'WorkingDir' (Mandatory Parameter) which's used as the base folder when searching for files recursively (using 'Get-ChildItem'), other two parameters are, in order from right to left, the Optional 'ExcludeFiles', which can be a path to a file, folder, or pattern-matched (like '*.png'), and the 'ProgressStatusMessage', which's used in Progress Bar.

        .EXAMPLE
        Invoke-Preprocessing -WorkingDir "DRIVE:\Path\To\Folder\" -ExcludedFiles @('file.txt', '.\.git\', '*.png') -ProgressStatusMessage "Doing Preprocessing" -ProgressActivity "Re-Formatting Code"

        Same as Example No. 1, but uses 'ProgressActivity' which's used in Progress Bar.

        .EXAMPLE
        Invoke-Preprocessing -Skip -WorkingDir "DRIVE:\Path\To\Folder\" -ExcludedFiles @('file.txt', '.\.git\', '*.png') -ProgressStatusMessage "Doing Preprocessing"

    #>

    param (
        [Parameter(Mandatory, position=1)]
        [ValidateScript({[System.IO.Path]::IsPathRooted($_)})]
        [string]$WorkingDir,

        [Parameter(position=2)]
        [string[]]$ExcludedFiles,

        [Parameter(Mandatory, position=3)]
        [string]$ProgressStatusMessage,

        [Parameter(position=4)]
        [string]$ProgressActivity = "Preprocessing"
    )

    if (-NOT (Test-Path -PathType Container -Path "$WorkingDir")) {
        throw "[Invoke-Preprocessing] Invalid Parameter Value for 'WorkingDir', passed value: '$WorkingDir'. Either the path is a File or Non-Existing/Invlid, please double check your code."
    }

    $InternalExcludedFiles = [System.Collections.Generic.List[string]]::new($ExcludedFiles.Count)
    ForEach ($excludedFile in $ExcludedFiles) {
        $InternalExcludedFiles.Add($excludedFile) | Out-Null
    }

    # Validate the ExcludedItems List before continuing on
    if ($ExcludedFiles.Count -gt 0) {
        ForEach ($excludedFile in $ExcludedFiles) {
            $filePath = "$(($WorkingDir -replace ('\\$', '')) + '\' + ($excludedFile -replace ('\.\\', '')))"
            # Only attempt to create the directory if the excludedFile ends with '\'
            if ($excludedFile -match '\\$' -and -not (Test-Path "$filePath")) {
                New-Item -Path "$filePath" -ItemType Directory -Force | Out-Null
            }
            $files = Get-ChildItem -Recurse -Path "$filePath" -File -Force
            if ($files.Count -gt 0) {
                ForEach ($file in $files) {
                    $InternalExcludedFiles.Add("$($file.FullName)") | Out-Null
                }
            } else { $failedFilesList += "'$filePath', " }
        }
        $failedFilesList = $failedFilesList -replace (',\s*$', '')
    }

    # Get Files List
    [System.Collections.ArrayList]$files = Get-ChildItem -LiteralPath $WorkingDir -Recurse -Exclude $InternalExcludedFiles -File -Force

    # Only keep the 'FullName' Property for every entry in the list
    for ($i = 0; $i -lt $files.Count; $i++) {
        $file = $files[$i]
        $files[$i] = $file.FullName
    }

    # If a file(s) are found in Exclude List,
    # Remove the file from files list.
    ForEach ($excludedFile in $InternalExcludedFiles) {
        $index = $files.IndexOf("$excludedFile")
        if ($index -ge 0) { $files.RemoveAt($index) }
    }

    # Define a path to store the file hashes
    $hashFilePath = Join-Path -Path $WorkingDir -ChildPath ".preprocessor_hashes.json"

    # Load existing hashes if the file exists
    $existingHashes = @{}
    if (Test-Path -Path $hashFilePath) {
        # intentionally dosn't use ConvertFrom-Json -AsHashtable as it isn't supported on old powershell versions
        $file_content = Get-Content -Path $hashFilePath | ConvertFrom-Json 
        foreach ($property in $file_content.PSObject.Properties) {
            $existingHashes[$property.Name] = $property.Value
        }
    }

    $newHashes = @{}
    $changedFiles = @()
    $hashingAlgorithm = "MD5"
    foreach ($file in $files){
        # Calculate the hash of the file
        $hash = Get-FileHash -Path $file -Algorithm $hashingAlgorithm | Select-Object -ExpandProperty Hash
        $newHashes[$file] = $hash

        # Check if the hash already exists in the existing hashes
        if (($existingHashes.ContainsKey($file) -and $existingHashes[$file] -eq $hash)) {
            # Skip processing this file as it hasn't changed
            continue;
        }
        else {
            # If the hash doesn't exist or has changed, add it to the changed files list
            $changedFiles += $file
        }
    }

    $files = $changedFiles
    $numOfFiles = $files.Count
    Write-Debug "[Invoke-Preprocessing] Files Changed: $numOfFiles"

    if ($numOfFiles -eq 0){
        Write-Debug "[Invoke-Preprocessing] Found 0 Files to Preprocess inside 'WorkingDir' Directory : '$WorkingDir'."
        return
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
        $newHashes[$fullFileName] = Get-FileHash -Path $fullFileName -Algorithm $hashingAlgorithm | Select-Object -ExpandProperty Hash

        Write-Progress -Activity $ProgressActivity -Status "$ProgressStatusMessage - Finished $i out of $numOfFiles" -PercentComplete (($i/$numOfFiles)*100)
    }

    Write-Progress -Activity $ProgressActivity -Status "$ProgressStatusMessage - Finished Task Successfully" -Completed

    # Save the new hashes to the file  
    $newHashes | ConvertTo-Json -Depth 10 | Set-Content -Path $hashFilePath
}
