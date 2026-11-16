function Get-WinUtilISOCleanupTree {
    param([Parameter(Mandatory)][string]$WorkDir)

    $root = [System.IO.DirectoryInfo]::new([System.IO.Path]::GetFullPath($WorkDir))
    Assert-WinUtilISOCleanupRoot -WorkDir $root.FullName

    if (-not ('WinUtilCleanupDirectoryHandle' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
public static class WinUtilCleanupDirectoryHandle {
    [StructLayout(LayoutKind.Sequential)]
    private struct FileInformation {
        public uint Attributes;
        public System.Runtime.InteropServices.ComTypes.FILETIME Creation, Access, Write;
        public uint Volume, SizeHigh, SizeLow, Links, IndexHigh, IndexLow;
    }
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern SafeFileHandle CreateFileW(string path, uint access, uint share, IntPtr security, uint creation, uint flags, IntPtr template);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool GetFileInformationByHandle(SafeFileHandle handle, out FileInformation info);
    public static SafeFileHandle Open(string path) {
        // LIST_DIRECTORY | READ_ATTRIBUTES, SHARE_READ, OPEN_EXISTING, BACKUP_SEMANTICS | OPEN_REPARSE_POINT.
        // Holding these handles prevents directory rename, replacement, and reparse-data writes.
        var handle = CreateFileW(path, 0x81, 1, IntPtr.Zero, 3, 0x02200000, IntPtr.Zero);
        if (handle.IsInvalid) { var error = Marshal.GetLastWin32Error(); handle.Dispose(); throw new Win32Exception(error, "Cannot lock ISO cleanup directory: " + path); }
        FileInformation info;
        if (!GetFileInformationByHandle(handle, out info)) { var error = Marshal.GetLastWin32Error(); handle.Dispose(); throw new Win32Exception(error); }
        if ((info.Attributes & 0x400) != 0 || (info.Attributes & 0x10) == 0) {
            handle.Dispose();
            throw new IOException("Refusing a reparse point or non-directory during ISO cleanup: " + path);
        }
        return handle;
    }
}

'@
    }

    $locks = @{}
    $files = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    $directories = [System.Collections.Generic.List[System.IO.DirectoryInfo]]::new()
    try {
        # Anchor the whole path from the volume down, so an ancestor cannot be renamed either.
        $ancestors = [System.Collections.Generic.List[string]]::new()
        for ($parent = $root; $null -ne $parent; $parent = $parent.Parent) { $ancestors.Add($parent.FullName) }
        $ancestors.Reverse()
        foreach ($path in $ancestors) { $locks[$path] = [WinUtilCleanupDirectoryHandle]::Open($path) }

        $pending = [System.Collections.Generic.Stack[string]]::new()
        $pending.Push($root.FullName)
        while ($pending.Count -gt 0) {
            foreach ($item in (Get-ChildItem -LiteralPath $pending.Pop() -Force -ErrorAction Stop)) {
                if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                    throw "Refusing a reparse point during ISO cleanup: '$($item.FullName)'."
                }
                if ($item.PSIsContainer) {
                    $locks[$item.FullName] = [WinUtilCleanupDirectoryHandle]::Open($item.FullName)
                    $directories.Add($item)
                    $pending.Push($item.FullName)
                } else {
                    $files.Add($item)
                }
            }
        }
        [pscustomobject]@{
            Root = $root.FullName
            Files = $files.ToArray()
            Directories = @($directories | Sort-Object { $_.FullName.Length } -Descending)
            Locks = $locks
        }
    } catch {
        foreach ($handle in $locks.Values) { $handle.Dispose() }
        throw
    }
}

function Assert-WinUtilISOCleanupRoot {
    param([string]$WorkDir)

    $root = [System.IO.DirectoryInfo]::new([System.IO.Path]::GetFullPath($WorkDir))
    $tempPath = [System.IO.DirectoryInfo]::new($env:TEMP).FullName.TrimEnd('\')
    if ($null -eq $root.Parent -or
        -not [string]::Equals($root.Parent.FullName.TrimEnd('\'), $tempPath, [StringComparison]::OrdinalIgnoreCase) -or
        -not $root.Name.StartsWith('WinUtil_Win11ISO', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing ISO cleanup outside a WinUtil working directory in TEMP: '$WorkDir'."
    }
    if ((Test-Path -LiteralPath $WorkDir) -and
        ((Get-Item -LiteralPath $WorkDir -Force -ErrorAction Stop).Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
        throw "Refusing a reparse point during ISO cleanup: '$WorkDir'."
    }
}
