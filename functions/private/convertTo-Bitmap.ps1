function ConvertTo-Bitmap {
    <#
    .SYNOPSIS
        Converts an image file to a Bitmap object
    
    .PARAMETER image
        The path to the image file to convert
    
    .EXAMPLE
        ConvertTo-Bitmap -imageFilePath "C:\path\to\image.png"
    #>
    param (
        $imageFilePath
    )

    # Read the image file as a byte array
    $imageBytes = [System.IO.File]::ReadAllBytes($imageFilePath)

    # Convert the byte array to a Base64 string
    $base64String = [System.Convert]::ToBase64String($imageBytes)

    # Create a streaming image by streaming the base64 string to a bitmap streamsource
    $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
    $bitmap.BeginInit()
    $bitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($base64String)
    $bitmap.EndInit()
    $bitmap.Freeze()

    # Return the bitmap object
    return $bitmap
}