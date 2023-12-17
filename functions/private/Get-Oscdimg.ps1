function Get-Oscdimg { 
    <#
    
        .DESCRIPTION
        This function will get oscdimg file for from github Release foldersand put it into env:temp

        .EXAMPLE
        Get-Oscdimg
    #>
    param( [Parameter(Mandatory=$true)] 
        $oscdimgPath = "$env:TEMP\oscdimg.exe"
    )
    
    $githubUserName = "KonTy"
    $downloadUrl = "https://github.com/$githubUserName/winutil/releases/download/oscdimg/oscdimg.exe"
    Invoke-RestMethod -Uri $downloadUrl -OutFile $oscdimgPath
    $hashResult = Get-FileHash -Path $oscdimgPath -Algorithm SHA256
    $sha256Hash = $hashResult.Hash

    Write-Host "[INFO] oscdimg.exe SHA-256 Hash: $sha256Hash"

    $expectedHash = "F62B91A06F94019A878DD9D1713FFBA2140B863C131EB78A329B4CCD6102960E"  # Replace with the actual expected hash
    if ($sha256Hash -eq $expectedHash) {
        Write-Host "Hashes match. File is verified."
    } else {
        Write-Host "Hashes do not match. File may be corrupted or tampered with."
    }
} 
