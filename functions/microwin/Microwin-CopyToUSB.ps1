function Microwin-CopyToUSB([string]$fileToCopy) {
    foreach ($volume in Get-Volume) {
        if ($volume -and $volume.FileSystemLabel -ieq "ventoy") {
            $destinationPath = "$($volume.DriveLetter):\"
            #Copy-Item -Path $fileToCopy -Destination $destinationPath -Force
            # Get the total size of the file
            $totalSize = (Get-Item "$fileToCopy").length

            Copy-Item -Path "$fileToCopy" -Destination "$destinationPath" -Verbose -Force -Recurse -Container -PassThru |
                ForEach-Object {
                    # Calculate the percentage completed
                    $completed = ($_.BytesTransferred / $totalSize) * 100

                    # Display the progress bar
                    Write-Progress -Activity "Copying File" -Status "Progress" -PercentComplete $completed -CurrentOperation ("{0:N2} MB / {1:N2} MB" -f ($_.BytesTransferred / 1MB), ($totalSize / 1MB))
                }

            Write-Host "File copied to Ventoy drive $($volume.DriveLetter)"
            return
        }
    }
    Write-Host "Ventoy USB Key is not inserted"
}
