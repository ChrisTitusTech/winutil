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
        } catch {
            # Print out the exception to console, and see what went wrong
            Write-Host "Could not finish 'ConvertTo-Icon' due to unhandled exception"
            Write-Host "Error: $_"
        }
        This Example makes a '.ico' file at "$env:TEMP\cttlogo.ico" File Path using the bitmap file
        found in "$env:TEMP\cttlogo.png", the function overrides the '.ico' File if it's found.
        this function will throw a FileNotFound Exception at the event of not finding the provided bitmap File Path.

        .EXAMPLE
        try {
            ConvertTo-Icon "$env:TEMP\cttlogo.png" "$env:TEMP\cttlogo.ico"
        } catch [System.IO.FileNotFoundException] {
            # Handle the thrown exception here...
        } catch {
            # Print out the exception to console, and see what went wrong
            Write-Host "Could not finish 'ConvertTo-Icon' due to unhandled exception"
            Write-Host "Error: $_"
        }
        This Example does the same as the previous one, but uses Positional Parameters instead

        .EXAMPLE
        try {
            ConvertTo-Icon -bitmapPath "$env:TEMP\cttlogo.png" -iconPath "$env:TEMP\cttlogo.ico" -overrideIconFile $false
        } catch [System.IO.FileNotFoundException] {
            # Handle the thrown exception here...
        } catch {
            # Print out the exception to console, and see what went wrong
            Write-Host "Could not finish 'ConvertTo-Icon' due to unhandled exception"
            Write-Host "Error: $_"
        }
        This Example make use of '-overrideIconFile' Optional Parameter, the default for this paramter is $true.
        By doing '-overrideIconFile $false', the 'ConvertTo-Icon' function will raise an exception that needs to be catched throw a 'catch' Code Block, otherwise it'll crash the running PowerShell instance/process.

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
        $b = [System.Drawing.Bitmap]::FromFile($bitmapPath)
        $icon = [System.Drawing.Icon]::FromHandle($b.GetHicon())
        $file = New-Object System.IO.FileStream($iconPath, 'OpenOrCreate')
        $icon.Save($file)
        $file.Close()
        $icon.Dispose()
        #explorer "/SELECT,$iconpath"
    }
    else {
        throw [System.IO.FileNotFoundException] "[ConvertTo-Icon] The provided bitmap File Path is not found at '$bitmapPath'."
    }
}
