#===========================================================================
# Tests - The logo rasterises at the size it is asked for
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:functionRoot = Join-Path $script:repoRoot "functions"

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    . (Join-Path $script:functionRoot "private\Invoke-WinUtilAssets.ps1")
    $global:sync = [hashtable]::Synchronized(@{})
}

Describe "Asset geometry" {
    It "knows the artwork's real extent" {
        # The logo used to be drawn on a 100 by 100 canvas while its paths ran to about 108 by
        # 110, so the right and bottom edges were cut off whatever size was rendered
        $bounds = [Windows.Rect]::Empty
        foreach ($shape in (Get-WinUtilAssetGeometry -Type "logo")) {
            $bounds = [Windows.Rect]::Union($bounds, $shape.Geometry.Bounds)
        }

        ($bounds.X + $bounds.Width) | Should -BeGreaterThan 100
        ($bounds.Y + $bounds.Height) | Should -BeGreaterThan 100
    }

    It "builds every asset it advertises" {
        foreach ($type in @("logo", "checkmark", "warning")) {
            @(Get-WinUtilAssetGeometry -Type $type).Count | Should -BeGreaterThan 0 -Because "$type should have shapes"
        }
    }

    It "refuses a type it does not know instead of drawing nothing" {
        { Get-WinUtilAssetGeometry -Type "nonsense" } | Should -Throw
    }
}

Describe "Rasterising" {
    It "produces a bitmap of the size asked for" {
        # it used to return a 100 by 100 bitmap whatever was requested, so anything larger was an
        # upscale of that and anything smaller threw away detail twice
        foreach ($size in @(16, 32, 48, 64, 256)) {
            $bitmap = Invoke-WinUtilAssets -Type "logo" -Size $size -Render

            $bitmap.PixelWidth | Should -Be $size
            $bitmap.PixelHeight | Should -Be $size
        }
    }

    It "fills the frame rather than leaving the artwork in a corner" {
        $size = 32
        $bitmap = Invoke-WinUtilAssets -Type "logo" -Size $size -Render

        $stride = $size * 4
        $pixels = New-Object 'byte[]' ($stride * $size)
        $bitmap.CopyPixels($pixels, $stride, 0)

        # how far the drawn pixels actually reach, as a share of the bitmap
        $minX = $size; $maxX = -1; $minY = $size; $maxY = -1
        for ($y = 0; $y -lt $size; $y++) {
            for ($x = 0; $x -lt $size; $x++) {
                if ($pixels[($y * $stride) + ($x * 4) + 3] -gt 40) {
                    if ($x -lt $minX) { $minX = $x }; if ($x -gt $maxX) { $maxX = $x }
                    if ($y -lt $minY) { $minY = $y }; if ($y -gt $maxY) { $maxY = $y }
                }
            }
        }

        (($maxX - $minX + 1) / $size) | Should -BeGreaterThan 0.85
        (($maxY - $minY + 1) / $size) | Should -BeGreaterThan 0.85
    }

    It "keeps the whole logo, including the edges that used to be cut" {
        $size = 64
        $bitmap = Invoke-WinUtilAssets -Type "logo" -Size $size -Render
        $stride = $size * 4
        $pixels = New-Object 'byte[]' ($stride * $size)
        $bitmap.CopyPixels($pixels, $stride, 0)

        # the lower right quarter held the part that was being clipped
        $drawn = 0
        for ($y = [int]($size / 2); $y -lt $size; $y++) {
            for ($x = [int]($size / 2); $x -lt $size; $x++) {
                if ($pixels[($y * $stride) + ($x * 4) + 3] -gt 40) { $drawn++ }
            }
        }

        $drawn | Should -BeGreaterThan 100
    }

    It "returns the same instance for a repeated request" {
        $first = Invoke-WinUtilAssets -Type "logo" -Size 32 -Render
        $second = Invoke-WinUtilAssets -Type "logo" -Size 32 -Render

        [object]::ReferenceEquals($first, $second) | Should -BeTrue
    }

    It "caches per size, so one size cannot serve another" {
        $small = Invoke-WinUtilAssets -Type "logo" -Size 16 -Render
        $large = Invoke-WinUtilAssets -Type "logo" -Size 48 -Render

        $small.PixelWidth | Should -Be 16
        $large.PixelWidth | Should -Be 48
    }

    It "is frozen, so it can be built away from the interface thread" {
        (Invoke-WinUtilAssets -Type "logo" -Size 32 -Render).IsFrozen | Should -BeTrue
    }
}

Describe "The control form of an asset" {
    It "is square, whatever shape the artwork is" {
        # fitting the box to the artwork made the logo, which is taller than it is wide, sit
        # against the edge of whatever it was placed next to
        $viewbox = Invoke-WinUtilAssets -Type "logo" -Size 25

        $viewbox.Width | Should -Be 25
        $viewbox.Height | Should -Be 25
        $viewbox.Child.Width | Should -Be $viewbox.Child.Height
    }

    It "leaves the artwork some room inside that square" {
        $canvas = (Invoke-WinUtilAssets -Type "logo" -Size 25).Child

        $bounds = [Windows.Rect]::Empty
        foreach ($shape in (Get-WinUtilAssetGeometry -Type "logo")) {
            $bounds = [Windows.Rect]::Union($bounds, $shape.Geometry.Bounds)
        }
        $longest = [Math]::Max($bounds.Width, $bounds.Height)

        $canvas.Width | Should -BeGreaterThan $longest
        # a little air, not half the box
        ($canvas.Width / $longest) | Should -BeLessThan 1.3
    }

    It "centres it, so the margins match on both sides" {
        $canvas = (Invoke-WinUtilAssets -Type "logo" -Size 25).Child
        $bounds = [Windows.Rect]::Empty
        foreach ($shape in (Get-WinUtilAssetGeometry -Type "logo")) {
            $bounds = [Windows.Rect]::Union($bounds, $shape.Geometry.Bounds)
        }

        $first = $canvas.Children[0]
        $left = [Windows.Controls.Canvas]::GetLeft($first)
        $top = [Windows.Controls.Canvas]::GetTop($first)

        $leftMargin = $left + $bounds.X
        $rightMargin = $canvas.Width - ($left + $bounds.X + $bounds.Width)
        $topMargin = $top + $bounds.Y
        $bottomMargin = $canvas.Height - ($top + $bounds.Y + $bounds.Height)

        [Math]::Abs($leftMargin - $rightMargin) | Should -BeLessThan 0.01
        [Math]::Abs($topMargin - $bottomMargin) | Should -BeLessThan 0.01
    }
}

Describe "Window icon" {
    It "asks the system for the sizes it wants rather than picking one" {
        # the metrics already account for the display scaling, which is what makes it sharp on
        # any monitor instead of scaled from a single bitmap
        $icon = Get-Content -Path (Join-Path $script:functionRoot "private\Set-WinUtilWindowIcon.ps1") -Raw

        $icon | Should -Match 'SM_CXSMICON'
        $icon | Should -Match 'SM_CXICON'
        $icon | Should -Match 'WM_SETICON'
        $icon | Should -Match 'Invoke-WinUtilAssets -Type "logo" -Size \$icon\.Size -Render'
    }

    It "keeps the handles alive and frees the ones it replaced" {
        $icon = Get-Content -Path (Join-Path $script:functionRoot "private\Set-WinUtilWindowIcon.ps1") -Raw

        $icon | Should -Match '\$sync\.WindowIconHandles = \$handles'
        $icon | Should -Match 'DestroyIcon'
    }

    It "runs once the window has a handle" {
        $ui = Get-Content -Path (Join-Path $script:functionRoot "private\Start-WinUtilUserInterface.ps1") -Raw

        $ui | Should -Match 'Add_Loaded\(\{[\s\S]{0,200}?Set-WinUtilWindowIcon'
    }
}
