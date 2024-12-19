function Copy-Files {
    <#

        .DESCRIPTION
            Copies the contents of a given ISO file to a given destination
        .PARAMETER Path
            The source of the files to copy
        .PARAMETER Destination
            The destination to copy the files to
        .PARAMETER Recurse
            Determines whether or not to copy all files of the ISO file, including those in subdirectories
        .PARAMETER Force
            Determines whether or not to overwrite existing files
        .EXAMPLE
            Copy-Files "D:" "C:\ISOFile" -Recurse -Force

    #>
    param (
        [string]$Path,
        [string]$Destination,
        [switch]$Recurse = $false,
        [switch]$Force = $false
    )

    try {

        $files = Get-ChildItem -Path $path -Recurse:$recurse
        Write-Host "Copy $($files.Count) file(s) from $path to $destination"

        foreach ($file in $files) {
            $status = "Copying file {0} of {1}: {2}" -f $counter, $files.Count, $file.Name
            Write-Progress -Activity "Copy disc image files" -Status $status -PercentComplete ($counter++/$files.count*100)
            $restpath = $file.FullName -Replace $path, ''

            if ($file.PSIsContainer -eq $true) {
                Write-Debug "Creating $($destination + $restpath)"
                New-Item ($destination+$restpath) -Force:$force -Type Directory -ErrorAction SilentlyContinue
            } else {
                Write-Debug "Copy from $($file.FullName) to $($destination+$restpath)"
                Copy-Item $file.FullName ($destination+$restpath) -ErrorAction SilentlyContinue -Force:$force
                Set-ItemProperty -Path ($destination+$restpath) -Name IsReadOnly -Value $false
            }
        }
        Write-Progress -Activity "Copy disc image files" -Status "Ready" -Completed
    } catch {
        Write-Host "Unable to Copy all the files due to an unhandled exception" -ForegroundColor Yellow
        Write-Host "Error information: $($_.Exception.Message)`n" -ForegroundColor Yellow
        Write-Host "Additional information:" -ForegroundColor Yellow
        Write-Host $PSItem.Exception.StackTrace
        # Write possible suggestions
        Write-Host "`nIf you are using an antivirus, try configuring exclusions"
    }
}
