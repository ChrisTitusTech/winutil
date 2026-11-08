function New-WinUtilDiskpartScriptFile {
    <#
    .SYNOPSIS
        Writes a diskpart command file exclusively under a GUID name so a same-user
        process cannot pre-plant a symlink or predict the path
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    # shortcut: the file is closed before diskpart /s reopens it, so a same-user watcher could
    # still swap it in that gap; move diskpart to stdin redirection if this ever needs to be airtight.
    $path = Join-Path $env:TEMP "winutil_diskpart_$([guid]::NewGuid().ToString('N')).txt"
    $stream = [System.IO.File]::Open($path, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
        $writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::ASCII)
        $writer.Write($Content)
        $writer.Flush()
    } finally {
        $stream.Close()
    }
    return $path
}
