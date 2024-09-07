function Invoke-WPFChangeColor {
    $random = New-Object System.Random
    function Get-RandomColor {
        $r = $random.Next(0, 256)
        $g = $random.Next(0, 256)
        $b = $random.Next(0, 256)
        
        # Return a new SolidColorBrush with random RGB values
        return [Windows.Media.SolidColorBrush]::new([Windows.Media.Color]::FromRgb($r, $g, $b))
    }
    $newBackground = Get-RandomColor
    $sync.Form.Resources["DMainBackgroundColor"] = $newBackground
}