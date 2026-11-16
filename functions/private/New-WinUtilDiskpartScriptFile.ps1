function New-WinUtilDiskpartScriptFile {
    <#
    .SYNOPSIS
        Writes a diskpart command file in an administrator-owned directory
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # ProgramData does not grant ordinary users DeleteChild, unlike the user's TEMP folder.
    # Apply the protected DACL and administrator owner at creation, before publishing the file.
    $directory = [System.IO.DirectoryInfo]::new((Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) "winutil_diskpart_$([guid]::NewGuid().ToString('N'))"))
    $security = [System.Security.AccessControl.DirectorySecurity]::new()
    $security.SetAccessRuleProtection($true, $false)
    $administrators = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-32-544')
    $security.SetOwner($administrators)
    foreach ($sid in @($administrators, [System.Security.Principal.SecurityIdentifier]::new('S-1-5-18'))) {
        $security.AddAccessRule([System.Security.AccessControl.FileSystemAccessRule]::new($sid, 'FullControl', 'ContainerInherit, ObjectInherit', 'None', 'Allow'))
    }
    if ($PSVersionTable.PSEdition -eq 'Core') {
        [System.IO.FileSystemAclExtensions]::Create($directory, $security)
    } else {
        $directory.Create($security)
    }
    $path = Join-Path $directory.FullName 'commands.txt'
    try {
        $fileSecurity = [System.Security.AccessControl.FileSecurity]::new()
        $fileSecurity.SetAccessRuleProtection($true, $false)
        $fileSecurity.SetOwner($administrators)
        foreach ($sid in @($administrators, [System.Security.Principal.SecurityIdentifier]::new('S-1-5-18'))) {
            $fileSecurity.AddAccessRule([System.Security.AccessControl.FileSystemAccessRule]::new($sid, 'FullControl', 'Allow'))
        }
        $stream = if ($PSVersionTable.PSEdition -eq 'Core') {
            [System.IO.FileSystemAclExtensions]::Create([System.IO.FileInfo]::new($path), [System.IO.FileMode]::CreateNew, [System.Security.AccessControl.FileSystemRights]::Write, [System.IO.FileShare]::None, 4096, [System.IO.FileOptions]::None, $fileSecurity)
        } else {
            [System.IO.FileStream]::new($path, [System.IO.FileMode]::CreateNew, [System.Security.AccessControl.FileSystemRights]::Write, [System.IO.FileShare]::None, 4096, [System.IO.FileOptions]::None, $fileSecurity)
        }
        try {
            $writer = [System.IO.StreamWriter]::new($stream, [System.Text.Encoding]::ASCII)
            try { $writer.Write($Content) } finally { $writer.Dispose() }
        } finally {
            $stream.Dispose()
        }
    } catch {
        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $directory.FullName -Force -ErrorAction SilentlyContinue
        throw
    }
    return $path
}
