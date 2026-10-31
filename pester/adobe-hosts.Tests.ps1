#===========================================================================
# Tests - Adobe URL Block List only writes blocking entries to the hosts file
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $tweaks = Get-Content (Join-Path $script:repoRoot "config\tweaks.json") -Raw | ConvertFrom-Json
    $script:applyAdobeBlock = [scriptblock]::Create(($tweaks.WPFTweaksBlockAdobeNet.InvokeScript -join "`n"))

    function ipconfig { param([Parameter(ValueFromRemainingArguments = $true)]$Arguments) }

    $script:validList = @(
        "# Copyright (c) 1993-2009 Microsoft Corp.",
        "#",
        "#New Ver 27.0",
        "0.0.0.0 activate.adobe.com",
        "0.0.0.0   lmlicensing.adobe.com   # licensing",
        ""
    ) -join "`r`n"
}

Describe "Adobe URL Block List tweak" {
    BeforeEach {
        Mock Add-Content { }
        Mock ipconfig { }
        Mock Write-Host { }
    }

    It "appends a list that only blocks hosts" {
        Mock Invoke-RestMethod { $script:validList }

        & $script:applyAdobeBlock

        Should -Invoke Add-Content -Times 1 -Exactly -ParameterFilter { $Value -eq $script:validList }
    }

    It "refuses a list that redirects a host to a real address" {
        Mock Invoke-RestMethod { $script:validList + "`r`n203.0.113.7 login.example-bank.com" }

        { & $script:applyAdobeBlock } | Should -Throw "*not 0.0.0.0 blocks*"
        Should -Invoke Add-Content -Times 0 -Exactly
    }

    It "refuses a list without the marker that undo removes from" {
        Mock Invoke-RestMethod { "0.0.0.0 activate.adobe.com" }

        { & $script:applyAdobeBlock } | Should -Throw "*#New Ver*"
        Should -Invoke Add-Content -Times 0 -Exactly
    }
}
