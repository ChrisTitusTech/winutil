function Get-WinUtilCountryFlag {
    <#
    .SYNOPSIS
        Generates a small WPF vector flag icon for the specified country code.
    .DESCRIPTION
        Returns a XAML Viewbox with simplified vector flag shapes.
        EU member states automatically display the EU flag.
        Uses the same proven pattern as Get-WinUtilFlagIcon.
    .PARAMETER CountryCode
        ISO 3166-1 alpha-2 country code (e.g., "US", "FR", "DE").
    #>
    param (
        [string]$CountryCode
    )

    if ([string]::IsNullOrWhiteSpace($CountryCode)) { return $null }

    $CountryCode = $CountryCode.ToUpper()

    # EU member states -> show EU flag
    $euCountries = @(
        "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
        "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
        "PL", "PT", "RO", "SK", "SI", "ES", "SE"
    )

    if ($euCountries -contains $CountryCode) {
        $CountryCode = "EU"
    }

    # Same template structure as Get-WinUtilFlagIcon (proven to work)
    $xamlTemplate = @"
<Viewbox xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Width="16" Height="12" Stretch="Uniform">
    <Canvas Width="30" Height="20" VerticalAlignment="Center">
        {0}
    </Canvas>
</Viewbox>
"@
    $shapes = ""

    switch ($CountryCode) {
        "EU" {
            # EU Flag: Blue background with gold circle of 12 dots
            $shapes = @'
            <Rectangle Fill="#003399" Width="30" Height="20" />
            <Ellipse Fill="#FFCC00" Width="1.5" Height="1.5" Canvas.Left="14.25" Canvas.Top="3" />
            <Ellipse Fill="#FFCC00" Width="1.5" Height="1.5" Canvas.Left="16.8" Canvas.Top="4.2" />
            <Ellipse Fill="#FFCC00" Width="1.5" Height="1.5" Canvas.Left="18" Canvas.Top="6.8" />
            <Ellipse Fill="#FFCC00" Width="1.5" Height="1.5" Canvas.Left="18" Canvas.Top="9.7" />
            <Ellipse Fill="#FFCC00" Width="1.5" Height="1.5" Canvas.Left="16.8" Canvas.Top="12.3" />
            <Ellipse Fill="#FFCC00" Width="1.5" Height="1.5" Canvas.Left="14.25" Canvas.Top="13.5" />
            <Ellipse Fill="#FFCC00" Width="1.5" Height="1.5" Canvas.Left="11.7" Canvas.Top="12.3" />
            <Ellipse Fill="#FFCC00" Width="1.5" Height="1.5" Canvas.Left="10.5" Canvas.Top="9.7" />
            <Ellipse Fill="#FFCC00" Width="1.5" Height="1.5" Canvas.Left="10.5" Canvas.Top="6.8" />
            <Ellipse Fill="#FFCC00" Width="1.5" Height="1.5" Canvas.Left="11.7" Canvas.Top="4.2" />
            <Ellipse Fill="#FFCC00" Width="1.5" Height="1.5" Canvas.Left="13" Canvas.Top="3.2" />
            <Ellipse Fill="#FFCC00" Width="1.5" Height="1.5" Canvas.Left="15.5" Canvas.Top="3.2" />
'@
        }
        "US" {
            # US Flag: Red/white stripes + blue canton
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
        "GB" {
            # UK: Blue bg with red/white cross
            $shapes = @'
            <Rectangle Fill="#012169" Width="30" Height="20" />
            <Rectangle Fill="White" Width="30" Height="4" Canvas.Top="8" />
            <Rectangle Fill="White" Width="4" Height="20" Canvas.Left="13" />
            <Rectangle Fill="#C8102E" Width="30" Height="2.4" Canvas.Top="8.8" />
            <Rectangle Fill="#C8102E" Width="2.4" Height="20" Canvas.Left="13.8" />
'@
        }
        "CA" {
            # Canada: Red-White-Red
            $shapes = @'
            <Rectangle Fill="#FF0000" Width="7.5" Height="20" Canvas.Left="0" />
            <Rectangle Fill="White" Width="15" Height="20" Canvas.Left="7.5" />
            <Rectangle Fill="#FF0000" Width="7.5" Height="20" Canvas.Left="22.5" />
            <Rectangle Fill="#FF0000" Width="3" Height="6" Canvas.Left="13.5" Canvas.Top="7" />
'@
        }
        "AU" {
            # Australia: Blue with Union Jack hint + star
            $shapes = @'
            <Rectangle Fill="#00008B" Width="30" Height="20" />
            <Rectangle Fill="White" Width="12" Height="2" Canvas.Top="4" />
            <Rectangle Fill="White" Width="2" Height="10" Canvas.Left="5" />
            <Rectangle Fill="#C8102E" Width="12" Height="1.2" Canvas.Top="4.4" />
            <Rectangle Fill="#C8102E" Width="1.2" Height="10" Canvas.Left="5.4" />
            <Ellipse Fill="White" Width="2" Height="2" Canvas.Left="20" Canvas.Top="14" />
'@
        }
        "JP" {
            # Japan: White + red circle
            $shapes = @'
            <Rectangle Fill="White" Width="30" Height="20" />
            <Ellipse Fill="#BC002D" Width="10" Height="10" Canvas.Left="10" Canvas.Top="5" />
'@
        }
        "CN" {
            # China: Red + yellow star
            $shapes = @'
            <Rectangle Fill="#DE2910" Width="30" Height="20" />
            <Ellipse Fill="#FFDE00" Width="4" Height="4" Canvas.Left="3" Canvas.Top="3" />
'@
        }
        "KR" {
            # South Korea: White + red/blue yin-yang
            $shapes = @'
            <Rectangle Fill="White" Width="30" Height="20" />
            <Ellipse Fill="#C60C30" Width="8" Height="4" Canvas.Left="11" Canvas.Top="5.5" />
            <Ellipse Fill="#003478" Width="8" Height="4" Canvas.Left="11" Canvas.Top="9.5" />
'@
        }
        "CH" {
            # Switzerland: Red + white cross
            $shapes = @'
            <Rectangle Fill="#FF0000" Width="30" Height="20" />
            <Rectangle Fill="White" Width="10" Height="3" Canvas.Left="10" Canvas.Top="8.5" />
            <Rectangle Fill="White" Width="3" Height="10" Canvas.Left="13.5" Canvas.Top="5" />
'@
        }
        "IN" {
            # India: Saffron-White-Green
            $shapes = @'
            <Rectangle Fill="#FF9933" Width="30" Height="6.66" Canvas.Top="0" />
            <Rectangle Fill="White" Width="30" Height="6.66" Canvas.Top="6.66" />
            <Rectangle Fill="#138808" Width="30" Height="6.66" Canvas.Top="13.32" />
            <Ellipse Fill="#000080" Width="3" Height="3" Canvas.Left="13.5" Canvas.Top="8.5" />
'@
        }
        "NO" {
            # Norway: Red bg + blue/white cross
            $shapes = @'
            <Rectangle Fill="#BA0C2F" Width="30" Height="20" />
            <Rectangle Fill="White" Width="4" Height="20" Canvas.Left="8" />
            <Rectangle Fill="White" Width="30" Height="4" Canvas.Top="8" />
            <Rectangle Fill="#00205B" Width="2" Height="20" Canvas.Left="9" />
            <Rectangle Fill="#00205B" Width="30" Height="2" Canvas.Top="9" />
'@
        }
        "IL" {
            # Israel: White + blue stripes
            $shapes = @'
            <Rectangle Fill="White" Width="30" Height="20" />
            <Rectangle Fill="#0038B8" Width="30" Height="3" Canvas.Top="2" />
            <Rectangle Fill="#0038B8" Width="30" Height="3" Canvas.Top="15" />
'@
        }
        "RU" {
            # Russia: White-Blue-Red
            $shapes = @'
            <Rectangle Fill="White" Width="30" Height="6.66" Canvas.Top="0" />
            <Rectangle Fill="#0039A6" Width="30" Height="6.66" Canvas.Top="6.66" />
            <Rectangle Fill="#D52B1E" Width="30" Height="6.66" Canvas.Top="13.32" />
'@
        }
        "NZ" {
            # New Zealand: Blue + red stars
            $shapes = @'
            <Rectangle Fill="#00247D" Width="30" Height="20" />
            <Ellipse Fill="#CC142B" Width="2" Height="2" Canvas.Left="22" Canvas.Top="5" />
            <Ellipse Fill="#CC142B" Width="2" Height="2" Canvas.Left="24" Canvas.Top="8" />
            <Ellipse Fill="#CC142B" Width="2" Height="2" Canvas.Left="23" Canvas.Top="12" />
            <Ellipse Fill="#CC142B" Width="2" Height="2" Canvas.Left="20" Canvas.Top="14" />
'@
        }
        "TW" {
            # Taiwan: Red + blue canton with white sun
            $shapes = @'
            <Rectangle Fill="#FE0000" Width="30" Height="20" />
            <Rectangle Fill="#000095" Width="15" Height="10" Canvas.Left="0" Canvas.Top="0" />
            <Ellipse Fill="White" Width="5" Height="5" Canvas.Left="5" Canvas.Top="2.5" />
'@
        }
        "ZA" {
            # South Africa: Color bands
            $shapes = @'
            <Rectangle Fill="#E03C31" Width="30" Height="6.66" Canvas.Top="0" />
            <Rectangle Fill="White" Width="30" Height="1" Canvas.Top="6.66" />
            <Rectangle Fill="#007749" Width="30" Height="5.66" Canvas.Top="7.66" />
            <Rectangle Fill="White" Width="30" Height="1" Canvas.Top="13.32" />
            <Rectangle Fill="#001489" Width="30" Height="6.66" Canvas.Top="14.32" />
'@
        }
        "BR" {
            # Brazil: Green + yellow diamond + blue circle
            $shapes = @'
            <Rectangle Fill="#009B3A" Width="30" Height="20" />
            <Polygon Fill="#FEDF00" Points="15,2 27,10 15,18 3,10" />
            <Ellipse Fill="#002776" Width="7" Height="7" Canvas.Left="11.5" Canvas.Top="6.5" />
'@
        }
        "SG" {
            # Singapore: Red top, White bottom
            $shapes = @'
            <Rectangle Fill="#EF3340" Width="30" Height="10" Canvas.Top="0" />
            <Rectangle Fill="White" Width="30" Height="10" Canvas.Top="10" />
'@
        }
        "UA" {
            # Ukraine: Blue-Yellow
            $shapes = @'
            <Rectangle Fill="#005BBB" Width="30" Height="10" Canvas.Top="0" />
            <Rectangle Fill="#FFD500" Width="30" Height="10" Canvas.Top="10" />
'@
        }
        "AE" {
            # UAE: Green-White-Black horizontal + Red vertical
            $shapes = @'
            <Rectangle Fill="#00732F" Width="30" Height="6.66" Canvas.Top="0" />
            <Rectangle Fill="White" Width="30" Height="6.66" Canvas.Top="6.66" />
            <Rectangle Fill="Black" Width="30" Height="6.66" Canvas.Top="13.32" />
            <Rectangle Fill="#FF0000" Width="7.5" Height="20" Canvas.Left="0" />
'@
        }
        "TR" {
            # Turkey: Red + white crescent hint
            $shapes = @'
            <Rectangle Fill="#E30A17" Width="30" Height="20" />
            <Ellipse Fill="White" Width="7" Height="7" Canvas.Left="9" Canvas.Top="6.5" />
            <Ellipse Fill="#E30A17" Width="5.5" Height="5.5" Canvas.Left="10.5" Canvas.Top="7.25" />
'@
        }
        "AR" {
            # Argentina: Blue-White-Blue + sun
            $shapes = @'
            <Rectangle Fill="#74ACDF" Width="30" Height="6.66" Canvas.Top="0" />
            <Rectangle Fill="White" Width="30" Height="6.66" Canvas.Top="6.66" />
            <Rectangle Fill="#74ACDF" Width="30" Height="6.66" Canvas.Top="13.32" />
            <Ellipse Fill="#F6B40E" Width="3" Height="3" Canvas.Left="13.5" Canvas.Top="8.5" />
'@
        }
        "VN" {
            # Vietnam: Red + yellow star
            $shapes = @'
            <Rectangle Fill="#DA251D" Width="30" Height="20" />
            <Ellipse Fill="#FFFF00" Width="6" Height="6" Canvas.Left="12" Canvas.Top="7" />
'@
        }
        "BY" {
            # Belarus: Red-Green
            $shapes = @'
            <Rectangle Fill="#CF101A" Width="30" Height="13.3" Canvas.Top="0" />
            <Rectangle Fill="#007C30" Width="30" Height="6.7" Canvas.Top="13.3" />
'@
        }
        "EG" {
            # Egypt: Red-White-Black
            $shapes = @'
            <Rectangle Fill="#CE1126" Width="30" Height="6.66" Canvas.Top="0" />
            <Rectangle Fill="White" Width="30" Height="6.66" Canvas.Top="6.66" />
            <Rectangle Fill="Black" Width="30" Height="6.66" Canvas.Top="13.32" />
'@
        }
        "HU" {
            # Hungary: Red-White-Green
            $shapes = @'
            <Rectangle Fill="#CE2939" Width="30" Height="6.66" Canvas.Top="0" />
            <Rectangle Fill="White" Width="30" Height="6.66" Canvas.Top="6.66" />
            <Rectangle Fill="#477050" Width="30" Height="6.66" Canvas.Top="13.32" />
'@
        }
        "SK" {
            # Slovakia: White-Blue-Red
            $shapes = @'
            <Rectangle Fill="White" Width="30" Height="6.66" Canvas.Top="0" />
            <Rectangle Fill="#0B4EA2" Width="30" Height="6.66" Canvas.Top="6.66" />
            <Rectangle Fill="#EE1C25" Width="30" Height="6.66" Canvas.Top="13.32" />
'@
        }
        "HR" {
            # Croatia: Red-White-Blue
            $shapes = @'
            <Rectangle Fill="#FF0000" Width="30" Height="6.66" Canvas.Top="0" />
            <Rectangle Fill="White" Width="30" Height="6.66" Canvas.Top="6.66" />
            <Rectangle Fill="#171796" Width="30" Height="6.66" Canvas.Top="13.32" />
'@
        }
        "LV" {
            # Latvia: Maroon-White-Maroon
            $shapes = @'
            <Rectangle Fill="#9E3039" Width="30" Height="8" Canvas.Top="0" />
            <Rectangle Fill="White" Width="30" Height="4" Canvas.Top="8" />
            <Rectangle Fill="#9E3039" Width="30" Height="8" Canvas.Top="12" />
'@
        }
        "BG" {
            # Bulgaria: White-Green-Red
            $shapes = @'
            <Rectangle Fill="White" Width="30" Height="6.66" Canvas.Top="0" />
            <Rectangle Fill="#00966E" Width="30" Height="6.66" Canvas.Top="6.66" />
            <Rectangle Fill="#D62612" Width="30" Height="6.66" Canvas.Top="13.32" />
'@
        }
        "EE" {
            # Estonia: Blue-Black-White
            $shapes = @'
            <Rectangle Fill="#0072CE" Width="30" Height="6.66" Canvas.Top="0" />
            <Rectangle Fill="Black" Width="30" Height="6.66" Canvas.Top="6.66" />
            <Rectangle Fill="White" Width="30" Height="6.66" Canvas.Top="13.32" />
'@
        }
        "DK" {
            # Denmark: Red + white cross
            $shapes = @'
            <Rectangle Fill="#C60C30" Width="30" Height="20" />
            <Rectangle Fill="White" Width="3.75" Height="20" Canvas.Left="9.375" />
            <Rectangle Fill="White" Width="30" Height="4" Canvas.Top="8" />
'@
        }
        "SE" {
            # Sweden: Blue + yellow cross
            $shapes = @'
            <Rectangle Fill="#006AA7" Width="30" Height="20" />
            <Rectangle Fill="#FECC00" Width="3.75" Height="20" Canvas.Left="9.375" />
            <Rectangle Fill="#FECC00" Width="30" Height="4" Canvas.Top="8" />
'@
        }
        default {
            # Globe fallback: simple gray globe
            $shapes = @'
            <Rectangle Fill="#E8E8E8" Width="30" Height="20" />
            <Ellipse Fill="#B0BEC5" Width="12" Height="12" Canvas.Left="9" Canvas.Top="4" />
            <Ellipse Stroke="#78909C" StrokeThickness="0.5" Fill="Transparent" Width="6" Height="12" Canvas.Left="12" Canvas.Top="4" />
            <Rectangle Fill="#78909C" Width="12" Height="0.5" Canvas.Left="9" Canvas.Top="10" />
'@
        }
    }

    $xaml = $xamlTemplate -f $shapes
    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::New($xaml))
    return [Windows.Markup.XamlReader]::Load($reader)
}
