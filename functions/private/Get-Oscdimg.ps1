function Get-Oscdimg { 
    <#
    
        .DESCRIPTION
        This function will download oscdimg file from github Release folders and put it into env:temp folder

        .EXAMPLE
        Get-Oscdimg
    #>
    param( [Parameter(Mandatory=$true)] 
        [string]$oscdimgPath
    )
    $oscdimgPath = "$env:TEMP\oscdimg.exe"
    $downloadUrl = "https://github.com/ChrisTitusTech/winutil/raw/main/releases/oscdimg.exe"
    Invoke-RestMethod -Uri $downloadUrl -OutFile $oscdimgPath
    $hashResult = Get-FileHash -Path $oscdimgPath -Algorithm SHA256
    $sha256Hash = $hashResult.Hash

    Write-Host "[INFO] oscdimg.exe SHA-256 Hash: $sha256Hash"

    $expectedHash = "AB9E161049D293B544961BFDF2D61244ADE79376D6423DF4F60BF9B147D3C78D"  # Replace with the actual expected hash
    if ($sha256Hash -eq $expectedHash) {
        Write-Host "Hashes match. File is verified."
    } else {
        Write-Host "Hashes do not match. File may be corrupted or tampered with."
    }
} 
