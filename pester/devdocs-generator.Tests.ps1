#===========================================================================
# Tests - devdocs-generator (Add-LinkAttributeToJson)
#===========================================================================
# Regression test for the "link" placement bug (re-fixes #4528 durably): the
# generator must always update/insert each item's top-level "link" and never
# place one inside a nested registry block, regardless of indentation or of
# braces appearing inside string values.
Describe "devdocs-generator Add-LinkAttributeToJson" {
    BeforeAll {
        # Dot-sourcing loads the functions only; the script's run-guard skips the
        # generation pipeline so this stays a fast, side-effect-free unit test.
        . "$PSScriptRoot/../tools/devdocs-generator.ps1"

        $script:cut    = 'WPF(WinUtil|Toggle|Features?|Tweaks?|Panel|Fix(es)?)?'
        $script:prefix = 'https://example/dev/tweaks'

        # Fixture covering the three tricky cases:
        #  - WPFToggleScrollbars : key indented deeper than its siblings (the real bug),
        #                          plus an existing top-level link that must be UPDATED.
        #  - WPFTweakBraces      : has { and } INSIDE a multi-line string value, which must
        #                          not be mistaken for structural braces.
        #  - WPFTweakNoLink      : has NO link yet and must get one INSERTED.
        $script:fixture = @'
{
    "WPFToggleScrollbars": {
    "Content": "Scrollbars",
    "category": "Customize Preferences",
    "registry": [
      {
        "Path": "HKCU:\\Control Panel",
        "DefaultState": "false"
      }
    ],
    "link": "https://OLD/x"
  },
  "WPFTweakBraces": {
    "Content": "Braces",
    "category": "Essential Tweaks",
    "InvokeScript": [
      "if ($true) { Write-Host '}' } else { Write-Host '{' }"
    ],
    "link": "https://OLD/y"
  },
  "WPFTweakNoLink": {
    "Content": "NoLink",
    "category": "Essential Tweaks",
    "registry": [
      {
        "Path": "HKLM:\\X",
        "DefaultState": "true"
      }
    ]
  }
}
'@
    }

    BeforeEach {
        $script:tmp = Join-Path $TestDrive 'fixture.json'
        Set-Content -Path $tmp -Value $fixture -Encoding utf8
        Add-LinkAttributeToJson -JsonFilePath $tmp -UrlPrefix $prefix -ItemNameToCut $cut
        $script:result = Get-Content -Path $tmp -Raw | ConvertFrom-Json
    }

    It "produces valid JSON" {
        { Get-Content -Path $tmp -Raw | ConvertFrom-Json } | Should -Not -Throw
    }

    It "never places a link inside a registry block" {
        @($result.PSObject.Properties.Value.registry.link | Where-Object { $_ }).Count | Should -Be 0
    }

    It "updates an existing top-level link in place, even when the key is mis-indented" {
        $result.WPFToggleScrollbars.link | Should -Be "$prefix/customize-preferences/scrollbars"
    }

    It "is not fooled by braces inside string values" {
        $result.WPFTweakBraces.link | Should -Be "$prefix/essential-tweaks/braces"
    }

    It "inserts a link when one is missing" {
        $result.WPFTweakNoLink.link | Should -Be "$prefix/essential-tweaks/nolink"
    }

    It "is idempotent (a second run changes nothing)" {
        $before = Get-Content -Path $tmp -Raw
        Add-LinkAttributeToJson -JsonFilePath $tmp -UrlPrefix $prefix -ItemNameToCut $cut
        Get-Content -Path $tmp -Raw | Should -Be $before
    }
}

Describe "devdocs-generator Get-RawJsonBlock" {
    BeforeAll {
        . "$PSScriptRoot/../tools/devdocs-generator.ps1"
    }

    It "finds the closing brace even when the item key is mis-indented" {
        $lines = (@'
{
    "WPFToggleScrollbars": {
    "Content": "Scrollbars",
    "registry": [
      { "Path": "HKCU:\\Control Panel" }
    ],
    "link": "https://OLD"
  },
  "WPFNext": { "Content": "n" }
}
'@) -split '\r?\n'
        $block = Get-RawJsonBlock -ItemName 'WPFToggleScrollbars' -JsonLines $lines
        $block         | Should -Not -BeNullOrEmpty
        $block.RawText | Should -Match 'Control Panel'
        $block.RawText | Should -Not -Match '"link"'   # trailing link is stripped
    }

    It "is not fooled by braces inside string values" {
        $lines = (@'
{
  "WPFTweakBraces": {
    "InvokeScript": [
      "if ($true) { Write-Host '}' } else { }"
    ]
  },
  "WPFNext": { "Content": "n" }
}
'@) -split '\r?\n'
        $block = Get-RawJsonBlock -ItemName 'WPFTweakBraces' -JsonLines $lines
        $block         | Should -Not -BeNullOrEmpty
        $block.RawText | Should -Match 'InvokeScript'
    }
}
