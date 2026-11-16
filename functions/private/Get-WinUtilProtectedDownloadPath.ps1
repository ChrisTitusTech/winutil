function Get-WinUtilProtectedDownloadPath {
    param([Parameter(Mandatory)][ValidateSet('ooshutup10.exe', 'autologin.exe')][string]$Name)

    $administrators = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-32-544')
    $system = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-18')
    $directory = [System.IO.DirectoryInfo]::new((Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'WinUtilDownloads'))
    $directorySecurity = [System.Security.AccessControl.DirectorySecurity]::new()
    $directorySecurity.SetAccessRuleProtection($true, $false)
    $directorySecurity.SetOwner($administrators)
    foreach ($sid in @($administrators, $system)) {
        $directorySecurity.AddAccessRule([System.Security.AccessControl.FileSystemAccessRule]::new($sid, 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'))
    }
    if ($PSVersionTable.PSEdition -eq 'Core') {
        [System.IO.FileSystemAclExtensions]::Create($directory, $directorySecurity)
    } else {
        $directory.Create($directorySecurity)
    }
    Assert-WinUtilProtectedDownloadPath -Path $directory.FullName

    $path = Join-Path $directory.FullName $Name
    if (-not (Test-Path -LiteralPath $path)) {
        $fileSecurity = [System.Security.AccessControl.FileSecurity]::new()
        $fileSecurity.SetAccessRuleProtection($true, $false)
        $fileSecurity.SetOwner($administrators)
        foreach ($sid in @($administrators, $system)) {
            $fileSecurity.AddAccessRule([System.Security.AccessControl.FileSystemAccessRule]::new($sid, 'FullControl', 'Allow'))
        }
        $stream = if ($PSVersionTable.PSEdition -eq 'Core') {
            [System.IO.FileSystemAclExtensions]::Create([System.IO.FileInfo]::new($path), [System.IO.FileMode]::CreateNew, [System.Security.AccessControl.FileSystemRights]::Write, [System.IO.FileShare]::None, 4096, [System.IO.FileOptions]::None, $fileSecurity)
        } else {
            [System.IO.FileStream]::new($path, [System.IO.FileMode]::CreateNew, [System.Security.AccessControl.FileSystemRights]::Write, [System.IO.FileShare]::None, 4096, [System.IO.FileOptions]::None, $fileSecurity)
        }
        $stream.Dispose()
    }
    Assert-WinUtilProtectedDownloadPath -Path $path
    return $path
}

function Assert-WinUtilProtectedDownloadPath {
    param([string]$Path)

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    $acl = Get-Acl -LiteralPath $Path -ErrorAction Stop
    $owner = $acl.GetOwner([System.Security.Principal.SecurityIdentifier]).Value
    $rules = @($acl.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier]))
    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -or
        -not $acl.AreAccessRulesProtected -or $owner -notin @('S-1-5-32-544', 'S-1-5-18') -or
        $rules.Count -ne 2 -or @($rules | Where-Object {
            $_.IdentityReference.Value -notin @('S-1-5-32-544', 'S-1-5-18') -or
            $_.AccessControlType -ne 'Allow' -or $_.FileSystemRights -ne 'FullControl'
        }).Count -gt 0) {
        throw "Refusing unprotected executable storage at '$Path'. Only Administrators and SYSTEM may control this path."
    }
}
