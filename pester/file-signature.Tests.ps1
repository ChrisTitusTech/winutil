#===========================================================================
# Tests - Authenticode check before launching downloaded executables
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\private\Assert-WinUtilFileSignature.ps1")

    function script:New-TestSignature {
        param([string]$Status, [string]$Subject)
        $certificate = if ($Subject) { [pscustomobject]@{ Subject = $Subject } } else { $null }
        [pscustomobject]@{ Status = $Status; SignerCertificate = $certificate }
    }
}

Describe "Assert-WinUtilFileSignature" {
    BeforeEach {
        $script:filePath = Join-Path $TestDrive "download.exe"
        Set-Content -LiteralPath $script:filePath -Value "payload"
    }

    It "accepts a valid signature from the expected publisher" {
        Mock Get-AuthenticodeSignature { New-TestSignature -Status "Valid" -Subject "CN=O&O Software GmbH, O=O&O Software GmbH, C=DE" }

        { Assert-WinUtilFileSignature -LiteralPath $script:filePath -Publisher "O&O Software GmbH" } | Should -Not -Throw
        Test-Path -LiteralPath $script:filePath | Should -BeTrue
    }

    It "accepts a quoted common name" {
        Mock Get-AuthenticodeSignature { New-TestSignature -Status "Valid" -Subject 'CN="Microsoft Corporation", O=Microsoft Corporation' }

        { Assert-WinUtilFileSignature -LiteralPath $script:filePath -Publisher "Microsoft Corporation" } | Should -Not -Throw
    }

    It "rejects and deletes an unsigned file" {
        Mock Get-AuthenticodeSignature { New-TestSignature -Status "NotSigned" }

        { Assert-WinUtilFileSignature -LiteralPath $script:filePath -Publisher "Microsoft Corporation" } | Should -Throw "*Signature verification failed*"
        Test-Path -LiteralPath $script:filePath | Should -BeFalse
    }

    It "rejects a valid signature from another publisher" {
        Mock Get-AuthenticodeSignature { New-TestSignature -Status "Valid" -Subject "CN=Contoso Ltd, O=Contoso" }

        { Assert-WinUtilFileSignature -LiteralPath $script:filePath -Publisher "Microsoft Corporation" } | Should -Throw
        Test-Path -LiteralPath $script:filePath | Should -BeFalse
    }

    It "rejects a publisher name that only appears as a prefix of the signer" {
        Mock Get-AuthenticodeSignature { New-TestSignature -Status "Valid" -Subject "CN=Microsoft Corporation Impostor, O=Evil" }

        { Assert-WinUtilFileSignature -LiteralPath $script:filePath -Publisher "Microsoft Corporation" } | Should -Throw
    }

    It "rejects a tampered file whose signature no longer matches" {
        Mock Get-AuthenticodeSignature { New-TestSignature -Status "HashMismatch" -Subject "CN=Microsoft Corporation" }

        { Assert-WinUtilFileSignature -LiteralPath $script:filePath -Publisher "Microsoft Corporation" } | Should -Throw
        Test-Path -LiteralPath $script:filePath | Should -BeFalse
    }
}

Describe "Downloaded tools are verified before they start" {
    It "<Name> checks the signature between download and launch" -ForEach @(
        @{ Name = "Invoke-WPFOOSU"; File = "functions\public\Invoke-WPFOOSU.ps1"; Publisher = "O&O Software GmbH" }
        @{ Name = "Invoke-WPFPanelAutologin"; File = "functions\public\Invoke-WPFPanelAutologin.ps1"; Publisher = "Microsoft Corporation" }
    ) {
        $source = Get-Content (Join-Path $script:repoRoot $File) -Raw
        $assertIndex = $source.IndexOf("Assert-WinUtilFileSignature")
        $launchIndex = $source.IndexOf("Start-Process")

        $assertIndex | Should -BeGreaterThan -1
        $assertIndex | Should -BeLessThan $launchIndex
        $source | Should -Match ([regex]::Escape("-Publisher `"$Publisher`""))
    }
}
