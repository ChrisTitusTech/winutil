function ConvertTo-Icon {
    <#

        .DESCRIPTION
        This function will convert BMP, GIF, EXIF, JPG, PNG and TIFF to ICO file

        .PARAMETER bitmapPath
        The file path to bitmap image to make '.ico' file out of.
        Supported file types according to Microsoft Documentation is the following:
        BMP, GIF, EXIF, JPG, PNG and TIFF.

        .PARAMETER iconPath
        The file path to write the new '.ico' resource.

        .PARAMETER overrideIconFile
        An optional boolean Parameter that makes the function overrides
        the Icon File Path if the file exists. Defaults to $true.

        .EXAMPLE
        try {
            ConvertTo-Icon -bitmapPath "$env:TEMP\cttlogo.png" -iconPath "$env:TEMP\cttlogo.ico"
        } catch [System.IO.FileNotFoundException] {
            # Handle the thrown exception here...
        }

        This Example makes a '.ico' file at "$env:TEMP\cttlogo.ico" File Path using the bitmap file
        found in "$env:TEMP\cttlogo.png", the function overrides the '.ico' File if it's found.
        this function will throw a FileNotFound Exception at the event of not finding the provided bitmap File Path.

        .EXAMPLE
        try {
            ConvertTo-Icon "$env:TEMP\cttlogo.png" "$env:TEMP\cttlogo.ico"
        } catch [System.IO.FileNotFoundException] {
            # Handle the thrown exception here...
        }

        This Example is the same as Example 1, but uses Positional Parameters instead.

        .EXAMPLE
        if (Test-Path "$env:TEMP\cttlogo.png") {
            ConvertTo-Icon -bitmapPath "$env:TEMP\cttlogo.png" -iconPath "$env:TEMP\cttlogo.ico"
        }

        This Example is same as Example 1, but checks if the bitmap File exists before calling 'ConvertTo-Icon' Function.
        This's the recommended way of using this function, as it doesn't require any try-catch blocks.

        .EXAMPLE
        try {
            ConvertTo-Icon -bitmapPath "$env:TEMP\cttlogo.png" -iconPath "$env:TEMP\cttlogo.ico" -overrideIconFile $false
        } catch [System.IO.FileNotFoundException] {
            # Handle the thrown exception here...
        }

        This Example make use of '-overrideIconFile' Optional Parameter, the default for this paramter is $true.
        By doing '-overrideIconFile $false', the 'ConvertTo-Icon' function will raise an exception that needs to be catched throw a 'catch' Code Block,
        otherwise it'll crash the running PowerShell instance/process.

    #>
    param(
        [Parameter(Mandatory=$true, position=0)]
        [string]$bitmapPath,
        [Parameter(Mandatory=$true, position=1)]
        [string]$iconPath,
        [Parameter(position=2)]
        [bool]$overrideIconFile = $true
    )

    Add-Type -AssemblyName System.Drawing

    if (Test-Path $bitmapPath) {
        if ((Test-Path $iconPath) -AND ($overrideIconFile -eq $false)) {
            Write-Host "[ConvertTo-Icon] Icon File is found at '$iconPath', and the 'overrideIconFile' Parameter is set to '$overrideIconFile'. Skipping the bitmap to icon convertion..." -ForegroundColor Yellow
            return
        }

        # Load bitmap file into memory, and make an Icon version out of it
        $b = [System.Drawing.Bitmap]::FromFile($bitmapPath)
        $icon = [System.Drawing.Icon]::FromHandle($b.GetHicon())

        # Create the folder for the new icon file if it doesn't exists
        $iconFolder = (New-Object System.IO.FileInfo($iconPath)).Directory.FullName
        [System.IO.Directory]::CreateDirectory($iconFolder) | Out-Null

        # Write the Icon File and do some cleaning-up
        $file = New-Object System.IO.FileStream($iconPath, 'OpenOrCreate')
        $icon.Save($file)
        $file.Close()
        $icon.Dispose()
    }
    else {
        throw [System.IO.FileNotFoundException] "[ConvertTo-Icon] The provided bitmap File Path is not found at '$bitmapPath'."
    }
}
