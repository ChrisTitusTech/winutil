    <#

    .SYNOPSIS
        Modifies the Taskbaritem of the WPF Form

    .PARAMETER state & value
        Value can be between 0 and 1, 0 being no progress done yet and 1 being fully completed
        State can be 'None' > No progress, 'Indeterminate' > Without value, 'Normal' > when using value, 'Error' > Red (when using value), 'Paused' > Yellow (when using value)

    .PARAMETER overlay
        Overlay icon to display on the taskbar item

    .EXAMPLE
        Set-WinUtilTaskbaritem -value 0.5 -state "Normal"
        Set-WinUtilTaskbaritem -state "Error"
        Set-WinUtilTaskbaritem -state "None"
        Set-WinUtilTaskbaritem -state "Indeterminate"
        Set-WinUtilTaskbaritem -overlay "C:\path\to\icon.ico"

    #>


function Set-WinUtilTaskbaritem {
    param (
        [double]$value,
        $state,
        $overlay
        #[string]$description
    )

    if ($value) {
        $sync["Form"].taskbarItemInfo.ProgressValue = $value
    }

    if ($state) {
        $sync["Form"].taskbarItemInfo.ProgressState = $state
    }

    if ($overlay -and (Test-Path $overlay)) {
        # Read the image file as a byte array
        $imageBytes = [System.IO.File]::ReadAllBytes($overlay)

        # Convert the byte array to a Base64 string
        [System.Convert]::ToBase64String($imageBytes)

        # Load the image file as a bitmap
        $bitmap = [System.Drawing.Bitmap]::new($overlay)

        # Create a streaming image by streaming the bitmap to a memory stream
        $memoryStream = [System.IO.MemoryStream]::new()
        $bitmap.Save($memoryStream, [System.Drawing.Imaging.ImageFormat]::Png)
        $memoryStream.Position = 0

        # Create a bitmap image from the memory stream
        $bitmapImage = [System.Windows.Media.Imaging.BitmapImage]::new()
        $bitmapImage.BeginInit()
        $bitmapImage.StreamSource = $memoryStream
        $bitmapImage.EndInit()
        $bitmapImage.Freeze()

        $sync["Form"].taskbarItemInfo.Overlay = $bitmapImage
    }
}