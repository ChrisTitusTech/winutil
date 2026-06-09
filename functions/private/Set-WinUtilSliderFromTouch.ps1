function Set-WinUtilSliderFromTouch {
    <#
    .SYNOPSIS
        Moves a Slider's value to a horizontal touch position. WPF Sliders ignore touch drag on touch-only devices, so this is wired up to the touch events manually.
    #>
    param (
        [Parameter(Mandatory)] $Slider,
        [Parameter(Mandatory)] [double]$PositionX
    )

    if ($Slider.ActualWidth -le 0) { return }

    $ratio = [math]::Min(1, [math]::Max(0, $PositionX / $Slider.ActualWidth))
    $value = $Slider.Minimum + ($ratio * ($Slider.Maximum - $Slider.Minimum))

    if ($Slider.TickFrequency -gt 0) {
        $steps = [math]::Round(($value - $Slider.Minimum) / $Slider.TickFrequency)
        $value = $Slider.Minimum + ($steps * $Slider.TickFrequency)
    }

    $Slider.Value = $value
}
