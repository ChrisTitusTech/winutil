function Assert-WinUtilFileSignature {
    <#
    .SYNOPSIS
        Throws unless a downloaded file carries a valid Authenticode signature from the expected publisher.

    .DESCRIPTION
        Call this between downloading an executable and starting it. The file is deleted when the
        check fails so a tampered or truncated download is never launched later by mistake.

    .PARAMETER LiteralPath
        The downloaded file to check.

    .PARAMETER Publisher
        The certificate common name the signer must have, for example 'Microsoft Corporation'.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$LiteralPath,

        [Parameter(Mandatory)]
        [string]$Publisher
    )

    $signature = Get-AuthenticodeSignature -LiteralPath $LiteralPath
    $subject = if ($signature.SignerCertificate) { [string]$signature.SignerCertificate.Subject } else { '' }
    $expected = '(^|,\s*)CN="?' + [regex]::Escape($Publisher) + '"?(,|$)'

    if ($signature.Status -ne 'Valid' -or $subject -notmatch $expected) {
        Remove-Item -LiteralPath $LiteralPath -Force -ErrorAction SilentlyContinue
        throw "Signature verification failed for $(Split-Path -Leaf $LiteralPath): expected a valid signature from '$Publisher' but found status '$($signature.Status)' and signer '$subject'. The file was deleted and not started."
    }
}
