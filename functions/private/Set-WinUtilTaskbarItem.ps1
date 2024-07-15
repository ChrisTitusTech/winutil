function Set-WinUtilTaskbaritem {
    <#

    .SYNOPSIS
        Modifies the Taskbaritem of the WPF Form

    .PARAMETER value
        Value can be between 0 and 1, 0 being no progress done yet and 1 being fully completed
        Value does not affect item without setting the state to 'Normal', 'Error' or 'Paused'
        Set-WinUtilTaskbaritem -value 0.5

    .PARAMETER state
        State can be 'None' > No progress, 'Indeterminate' > inf. loading gray, 'Normal' > Gray, 'Error' > Red, 'Paused' > Yellow
        no value needed:
        - Set-WinUtilTaskbaritem -state "None"
        - Set-WinUtilTaskbaritem -state "Indeterminate"
        value needed:
        - Set-WinUtilTaskbaritem -state "Error"
        - Set-WinUtilTaskbaritem -state "Normal"
        - Set-WinUtilTaskbaritem -state "Paused"

    .PARAMETER overlay
        Overlay icon to display on the taskbar item, there are the presets 'None', 'logo' and 'checkmark' or you can specify a path/link to an image file.
        CTT logo preset:
        - Set-WinUtilTaskbaritem -overlay "logo"
        Checkmark preset:
        - Set-WinUtilTaskbaritem -overlay "checkmark"
        No overlay:
        - Set-WinUtilTaskbaritem -overlay "None"
        Custom icon:
        - Set-WinUtilTaskbaritem -overlay "C:\path\to\icon.png"

    .PARAMETER description
        Description to display on the taskbar item preview
        Set-WinUtilTaskbaritem -description "This is a description"
    #>
    param (
        [string]$state,
        [double]$value,
        [string]$overlay,
        [string]$description
    )

    # TODO: Make a better solution for this function, accessing problem when calling Set-WinUtilTaskbaritem inside a runspace. Future me or other contributors, please fix this.
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

    if ($value) {
        $sync["Form"].taskbarItemInfo.ProgressValue = $value
    }

    if ($state) {
        switch ($state) {
            'None' { $sync["Form"].taskbarItemInfo.ProgressState = "None" }
            'Indeterminate' { $sync["Form"].taskbarItemInfo.ProgressState = "Indeterminate" }
            'Normal' { $sync["Form"].taskbarItemInfo.ProgressState = "Normal" }
            'Error' { $sync["Form"].taskbarItemInfo.ProgressState = "Error" }
            'Paused' { $sync["Form"].taskbarItemInfo.ProgressState = "Paused" }
            default { throw "[Set-WinUtilTaskbarItem] Invalid state" }
        }
    }

    if ($overlay) {
        switch ($overlay) {
            'logo' {
                $sync["Form"].taskbarItemInfo.Overlay = (ConvertTo-Bitmap -imageFilePath "$env:LOCALAPPDATA\winutil\cttlogo.png")
            }
            'checkmark' {
                $sync["Form"].taskbarItemInfo.Overlay = (ConvertTo-Bitmap -imageFilePath "$env:LOCALAPPDATA\winutil\cttcheckmark.png"])
            }
            'None' {
                $sync["Form"].taskbarItemInfo.Overlay = $null
            }
            default {
                if (Test-Path $overlay) {
                    $sync["Form"].taskbarItemInfo.Overlay = (ConvertTo-Bitmap -image $overlay)
                }
            }
        }
    }

    if ($description) {
        $sync["Form"].taskbarItemInfo.Description = $description
    }
}