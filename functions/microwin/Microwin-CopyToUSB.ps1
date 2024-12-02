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

            # Detect if config files are present, move them if they are, and configure the Ventoy drive to not bypass the requirements
            $customVentoyConfig = @'
{
    "control":[
        { "VTOY_WIN11_BYPASS_CHECK": "0" },
        { "VTOY_WIN11_BYPASS_NRO": "0" }
    ],
    "control_legacy":[
        { "VTOY_WIN11_BYPASS_CHECK": "0" },
        { "VTOY_WIN11_BYPASS_NRO": "0" }
    ],
    "control_uefi":[
        { "VTOY_WIN11_BYPASS_CHECK": "0" },
        { "VTOY_WIN11_BYPASS_NRO": "0" }
    ],
    "control_ia32":[
        { "VTOY_WIN11_BYPASS_CHECK": "0" },
        { "VTOY_WIN11_BYPASS_NRO": "0" }
    ],
    "control_aa64":[
        { "VTOY_WIN11_BYPASS_CHECK": "0" },
        { "VTOY_WIN11_BYPASS_NRO": "0" }
    ],
    "control_mips":[
        { "VTOY_WIN11_BYPASS_CHECK": "0" },
        { "VTOY_WIN11_BYPASS_NRO": "0" }
    ]
}
'@

            try {
                Write-Host "Writing custom Ventoy configuration. Please wait..."
                if (Test-Path -Path "$($volume.DriveLetter):\ventoy\ventoy.json" -PathType Leaf) {
                    Write-Host "A Ventoy configuration file exists. Moving it..."
                    Move-Item -Path "$($volume.DriveLetter):\ventoy\ventoy.json" -Destination "$($volume.DriveLetter):\ventoy\ventoy.json.old" -Force
                    Write-Host "Existing Ventoy configuration has been moved to `"ventoy.json.old`". Feel free to put your config back into the `"ventoy.json`" file."
                }
                if (-not (Test-Path -Path "$($volume.DriveLetter):\ventoy")) {
                    New-Item -Path "$($volume.DriveLetter):\ventoy" -ItemType Directory -Force | Out-Null
                }
                $customVentoyConfig | Out-File -FilePath "$($volume.DriveLetter):\ventoy\ventoy.json" -Encoding utf8 -Force
                Write-Host "The Ventoy drive has been successfully configured."
            } catch {
                Write-Host "Could not configure Ventoy drive. Error: $($_.Exception.Message)`n"
                Write-Host "Be sure to add the following configuration to the Ventoy drive by either creating a `"ventoy.json`" file in the `"ventoy`" directory (create it if it doesn't exist) or by editing an existing one: `n`n$customVentoyConfig`n"
                Write-Host "Failure to do this will cause conflicts with your target ISO file."
            }
            return
        }
    }
    Write-Host "Ventoy USB Key is not inserted"
}
