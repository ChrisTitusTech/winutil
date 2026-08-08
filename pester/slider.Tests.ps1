#===========================================================================
# Tests - Sliders move to where they are clicked
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:xaml = [xml](Get-Content -Path (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw)
}

Describe "Sliders" {
    It "goes to the point clicked instead of stepping" {
        # WPF leaves IsMoveToPointEnabled off by default, so a click on the track pages by
        # LargeChange rather than moving the thumb to the pointer
        $sliders = @($script:xaml.SelectNodes('//*[local-name()="Slider"]'))
        $sliders.Count | Should -BeGreaterThan 0

        foreach ($slider in $sliders) {
            $name = $slider.GetAttribute("Name")
            $slider.GetAttribute("IsMoveToPointEnabled") | Should -Be "True" -Because "$name should follow the click"
        }
    }

    It "does not page by a full unit" {
        # LargeChange defaults to 1.0. Over a range of 0.75 to 2.0 that is most of the track, so
        # a click on it toggled between the two ends.
        foreach ($slider in @($script:xaml.SelectNodes('//*[local-name()="Slider"]'))) {
            $name = $slider.GetAttribute("Name")
            $minimum = [double]$slider.GetAttribute("Minimum")
            $maximum = [double]$slider.GetAttribute("Maximum")
            $largeChange = $slider.GetAttribute("LargeChange")

            $largeChange | Should -Not -BeNullOrEmpty -Because "$name should say how far a page moves"
            ([double]$largeChange) | Should -BeLessOrEqual (($maximum - $minimum) / 2) -Because "$name pages a sensible amount"
        }
    }

    It "keeps the font scaling steps on the ticks it draws" {
        $slider = $script:xaml.SelectSingleNode('//*[local-name()="Slider"][@Name="FontScalingSlider"]')

        $slider | Should -Not -BeNullOrEmpty
        $slider.GetAttribute("IsSnapToTickEnabled") | Should -Be "True"
        $slider.GetAttribute("SmallChange") | Should -Be $slider.GetAttribute("TickFrequency")
    }
}
