function Get-WinUtilFlagIcon {
    <#
    .SYNOPSIS
        Generates a WPF vector icon for the specified language.
    .PARAMETER Language
        The language code (e.g., "en-US", "fr-FR").
    .RETURNVALUE
        A System.Windows.Controls.Viewbox containing the flag shapes.
    #>
    param (
        [string]$Language
    )

    $xamlTemplate = @"
<Viewbox xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Width="24" Height="16" Stretch="Uniform">
    <Canvas Width="30" Height="20" VerticalAlignment="Center">
        {0}
    </Canvas>
</Viewbox>
"@
    $shapes = ""

    switch ($Language) {
        "en-US" {
            # Simple US Flag: Blue canton + 7 stripes (4 red, 3 white)
            $shapes = @'
            <Rectangle Fill="Red" Width="30" Height="2.85" Canvas.Top="0" />
            <Rectangle Fill="White" Width="30" Height="2.85" Canvas.Top="2.85" />
            <Rectangle Fill="Red" Width="30" Height="2.85" Canvas.Top="5.7" />
            <Rectangle Fill="White" Width="30" Height="2.85" Canvas.Top="8.55" />
            <Rectangle Fill="Red" Width="30" Height="2.85" Canvas.Top="11.4" />
            <Rectangle Fill="White" Width="30" Height="2.85" Canvas.Top="14.25" />
            <Rectangle Fill="Red" Width="30" Height="2.85" Canvas.Top="17.1" />
            <Rectangle Fill="#3C3B6E" Width="12" Height="11.4" Canvas.Top="0" Canvas.Left="0" />
'@
        }
        "fr-FR" {
            # Blue, White, Red vertical
            $shapes = @'
            <Rectangle Fill="#002395" Width="10" Height="20" Canvas.Left="0" />
            <Rectangle Fill="White" Width="10" Height="20" Canvas.Left="10" />
            <Rectangle Fill="#ED2939" Width="10" Height="20" Canvas.Left="20" />
'@
        }
        "es-ES" {
            # Red, Yellow (x2), Red horizontal
            $shapes = @'
            <Rectangle Fill="#AA151B" Width="30" Height="5" Canvas.Top="0" />
            <Rectangle Fill="#F1BF00" Width="30" Height="10" Canvas.Top="5" />
            <Rectangle Fill="#AA151B" Width="30" Height="5" Canvas.Top="15" />
'@
        }
        "de-DE" {
            # Black, Red, Gold horizontal
            $shapes = @'
            <Rectangle Fill="Black" Width="30" Height="6.66" Canvas.Top="0" />
            <Rectangle Fill="#FF0000" Width="30" Height="6.66" Canvas.Top="6.66" />
            <Rectangle Fill="#FFCC00" Width="30" Height="6.66" Canvas.Top="13.32" />
'@
        }
        "it-IT" {
            # Green, White, Red vertical
            $shapes = @'
            <Rectangle Fill="#009246" Width="10" Height="20" Canvas.Left="0" />
            <Rectangle Fill="White" Width="10" Height="20" Canvas.Left="10" />
            <Rectangle Fill="#CE2B37" Width="10" Height="20" Canvas.Left="20" />
'@
        }
        "pt-PT" {
            # Green (2/5), Red (3/5) vertical
            $shapes = @'
            <Rectangle Fill="#006600" Width="12" Height="20" Canvas.Left="0" />
            <Rectangle Fill="#FF0000" Width="18" Height="20" Canvas.Left="12" />
'@
        }
        "pl-PL" {
            # White, Red horizontal
            $shapes = @'
            <Rectangle Fill="White" Width="30" Height="10" Canvas.Top="0" />
            <Rectangle Fill="#DC143C" Width="30" Height="10" Canvas.Top="10" />
'@
        }
        "nl-NL" {
            # Red, White, Blue horizontal
            $shapes = @'
            <Rectangle Fill="#AE1C28" Width="30" Height="6.66" Canvas.Top="0" />
            <Rectangle Fill="White" Width="30" Height="6.66" Canvas.Top="6.66" />
            <Rectangle Fill="#21468B" Width="30" Height="6.66" Canvas.Top="13.32" />
'@
        }
        "ro-RO" {
            # Blue, Yellow, Red vertical
            $shapes = @'
            <Rectangle Fill="#002B7F" Width="10" Height="20" Canvas.Left="0" />
            <Rectangle Fill="#FCD116" Width="10" Height="20" Canvas.Left="10" />
            <Rectangle Fill="#CE1126" Width="10" Height="20" Canvas.Left="20" />
'@
        }
        "sv-SE" {
            # Blue with Yellow Cross
            $shapes = @'
            <Rectangle Fill="#006AA7" Width="30" Height="20" />
            <Rectangle Fill="#FECC00" Width="3.75" Height="20" Canvas.Left="9.375" />
            <Rectangle Fill="#FECC00" Width="30" Height="4" Canvas.Top="8" />
'@
        }
        "cs-CZ" {
            # White top, Red bottom, Blue triangle
            $shapes = @'
            <Rectangle Fill="White" Width="30" Height="10" Canvas.Top="0" />
            <Rectangle Fill="#D7141A" Width="30" Height="10" Canvas.Top="10" />
            <Polygon Fill="#11457E" Points="0,0 15,10 0,20" />
'@
        }
        default { return $null }
    }

    $xaml = $xamlTemplate -f $shapes
    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::New($xaml))
    return [Windows.Markup.XamlReader]::Load($reader)
}
