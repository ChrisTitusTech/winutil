function New-WinUtilFossBadge {
    <#
        .SYNOPSIS
            Creates the FOSS marker: the open source keyhole on a green backdrop
        .DESCRIPTION
            Returns a fresh element on every call, because a WPF element can only have one parent.
            The artwork is authored in a 22x22 box and scaled by the Viewbox, so callers only pick a size.
        .PARAMETER Size
            Edge length of the badge in pixels
        .PARAMETER Round
            Use a full circle instead of the corner triangle, for the legend rather than an app entry
    #>
    param(
        [double]$Size = 24,
        [switch]$Round
    )

    $artwork = New-Object Windows.Controls.Grid
    $artwork.Width = 22
    $artwork.Height = 22

    $backdrop = New-Object Windows.Shapes.Path
    $backdrop.Fill = [Windows.Media.SolidColorBrush]::new([Windows.Media.Color]::FromRgb(19, 143, 83))
    $keyhole = New-Object Windows.Shapes.Path
    $keyhole.Stroke = [Windows.Media.SolidColorBrush]::new([Windows.Media.Color]::FromRgb(247, 247, 247))

    if ($Round) {
        $backdrop.Data = [Windows.Media.EllipseGeometry]::new([Windows.Point]::new(11, 11), 11, 11)
        # Keyhole centred in the circle, which has room for a larger ring than the triangle does
        $keyhole.Data = [Windows.Media.Geometry]::Parse("M 7.673,15.751 A 5.8,5.8 0 1 1 14.327,15.751")
        $keyhole.StrokeThickness = 3.4
    } else {
        # Triangle filling the top right corner, its outer corner rounded to match AppEntryBorderStyle
        $backdrop.Data = [Windows.Media.Geometry]::Parse("M 0,0 L 17,0 A 5,5 0 0 1 22,5 L 22,22 Z")
        # Keyhole centred on the triangle's incentre (15.56, 6.44) so it keeps the same
        # 1.8 clearance from all three edges
        $keyhole.Data = [Windows.Media.Geometry]::Parse("M 13.61,9.225 A 3.4,3.4 0 1 1 17.51,9.225")
        $keyhole.StrokeThickness = 2.4
    }

    $keyhole.StrokeStartLineCap = [Windows.Media.PenLineCap]::Round
    $keyhole.StrokeEndLineCap = [Windows.Media.PenLineCap]::Round
    [void]$artwork.Children.Add($backdrop)
    [void]$artwork.Children.Add($keyhole)

    $badge = New-Object Windows.Controls.Viewbox
    $badge.Width = $Size
    $badge.Height = $Size
    $badge.Child = $artwork
    $badge.ToolTip = "Free and Open Source Software"

    return $badge
}
