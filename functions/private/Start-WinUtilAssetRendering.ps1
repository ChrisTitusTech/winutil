function Start-WinUtilAssetRendering {
    <#
        .SYNOPSIS
            Renders the taskbar overlay bitmaps on a thread of their own

        .DESCRIPTION
            Rasterising the overlays costs the interface thread time it could spend getting the
            window up. The bitmaps are frozen before publication, so they can be built anywhere.

            Nothing waits on this: if the render has not finished when an overlay is asked for,
            Set-WinUtilTaskbaritem renders it in place.

            Needs STA for RenderTargetBitmap, which the shared worker pool is not.
    #>

    $runspace = [runspacefactory]::CreateRunspace((New-WinUtilSessionState))
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()

    $shell = [powershell]::Create()
    $shell.Runspace = $runspace
    [void]$shell.AddScript({
        Measure-WinUtilStep -Scope "UI" -Name "render taskbar overlays (off thread)" -ScriptBlock {
            Initialize-WinUtilTaskbarOverlayAssets -IncludeLogo $true -IncludeStatusAssets $true
        }
    })

    $handle = $shell.BeginInvoke()

    # One STA runspace for the app's lifetime: disposing it from the cleanup callback would mean
    # reshaping the compiled helper type, which is built once per session.
    Register-WinUtilRunspaceCleanup -PowerShell $shell -Handle $handle

    return $handle
}
