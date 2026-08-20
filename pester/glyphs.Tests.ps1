#===========================================================================
# Tests - Icon glyphs exist in the font that renders them

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

    It "assigns icon content as a string, never as a char" {
        # A char reaching Content is not laid out with the control's own icon font. It falls back
        # to whatever font claims the code point, which renders it in that font's colour and
        # metrics: the pause icon came out teal and a different size from the one beside it.
        $offenders = @()
        foreach ($file in (Get-ChildItem -Path (Join-Path $script:repoRoot "functions") -Filter *.ps1 -Recurse)) {
            foreach ($line in ((Get-Content -Path $file.FullName -Raw) -split "`r?`n")) {
                if ($line -match '^\s*#') { continue }
                # a property assignment, or a hashtable key that later becomes Content. A
                # comparison against a char is fine, and so is a variable that merely ends in Icon
                $assignsContent = $line -match '\.Content\s*=\s*[^=]*\[char\]0x[0-9A-Fa-f]{4}'
                $assignsIconKey = $line -match '^\s*Icon\s*=\s*\[char\]0x[0-9A-Fa-f]{4}'
                if (($assignsContent -or $assignsIconKey) -and $line -notmatch '\[string\]\(\[char\]') {
                    $offenders += "$($file.Name): $($line.Trim())"
                }
            }
        }

        if ($offenders.Count -gt 0) { throw ($offenders -join "`n") }
    }

    
}
