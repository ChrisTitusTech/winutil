function Get-WinUtilEnvironmentReportLogsPath {
    <#
    .SYNOPSIS
        Derives the companion logs .txt path from the environment report's JSON save path.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonPath
    )

    # ChangeExtension($JsonPath, $null) leaves a trailing dot instead of stripping it, so build the
    # name from its parts instead.
    $directory = [System.IO.Path]::GetDirectoryName($JsonPath)
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($JsonPath)
    return [System.IO.Path]::Combine($directory, "${baseName}_logs.txt")
}
