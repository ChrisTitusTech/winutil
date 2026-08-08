#===========================================================================
# Tests - Icon glyphs exist in the font that renders them
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    function script:Get-WinUtilGlyphTypeface {
        param([string]$FontName)

        $family = New-Object Windows.Media.FontFamily($FontName)
        $typefaces = @($family.GetTypefaces())
        if ($typefaces.Count -eq 0) { return $null }

        $glyphTypeface = $null
        if (-not $typefaces[0].TryGetGlyphTypeface([ref]$glyphTypeface)) { return $null }
        return $glyphTypeface
    }

    function script:Get-WinUtilIconCodePoints {
        $found = New-Object System.Collections.Generic.List[object]

        # &#xNNNN; in the markup
        $xaml = Get-Content -Path (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw
        foreach ($match in [regex]::Matches($xaml, '&#x([0-9A-Fa-f]{4});')) {
            $found.Add([pscustomobject]@{ Code = $match.Groups[1].Value.ToUpper(); Where = "inputXML.xaml" })
        }

        # [char]0xNNNN in the scripts that set icon content
        foreach ($file in (Get-ChildItem -Path (Join-Path $script:repoRoot "functions") -Filter *.ps1 -Recurse)) {
            $text = Get-Content -Path $file.FullName -Raw
            foreach ($match in [regex]::Matches($text, '\[char\]0x([0-9A-Fa-f]{4})')) {
                $found.Add([pscustomobject]@{ Code = $match.Groups[1].Value.ToUpper(); Where = $file.Name })
            }
        }

        return $found
    }
}

Describe "Icon glyphs" {
    It "uses only code points the icon font actually has" {
        # A code point the font lacks renders as an empty box, which reads as a broken control
        # rather than as a missing icon
        $glyphTypeface = Get-WinUtilGlyphTypeface -FontName "Segoe MDL2 Assets"
        if ($null -eq $glyphTypeface) {
            Set-ItResult -Skipped -Because "Segoe MDL2 Assets is not installed here"
            return
        }

        $missing = @()
        foreach ($icon in (Get-WinUtilIconCodePoints)) {
            $value = [Convert]::ToInt32($icon.Code, 16)
            # only the private use area holds icon glyphs; anything else is ordinary text
            if ($value -lt 0xE000 -or $value -gt 0xF8FF) { continue }
            if (-not $glyphTypeface.CharacterToGlyphMap.ContainsKey($value)) {
                $missing += "U+$($icon.Code) in $($icon.Where)"
            }
        }

        if ($missing.Count -gt 0) { throw ($missing -join "`n") }
    }

    It "uses the filled square for stop, not the hollow one" {
        # U+E71A is an outline square at button size and reads as a missing glyph
        $xaml = Get-Content -Path (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw
        $stopButton = ([regex]::Match($xaml, '<Button Name="WPFStopJobButton"[\s\S]*?/>')).Value

        $stopButton | Should -Match 'Content="&#xE73B;"'
        $stopButton | Should -Not -Match 'E71A'
    }

    It "pairs play and pause on the same button" {
        $pause = Get-Content -Path (Join-Path $script:repoRoot "functions\private\Wait-WinUtilJobPause.ps1") -Raw

        # E768 play to resume, E769 pause to hold
        $pause | Should -Match '0xE768'
        $pause | Should -Match '0xE769'
    }
}
