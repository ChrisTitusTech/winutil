function Start-WinUtilAssetRendering {
    <#
        .SYNOPSIS
            Renders the taskbar overlay bitmaps on a thread of their own

        .DESCRIPTION
            Rasterising the overlays costs the interface thread time it could spend getting the
            window up. The bitmaps are frozen before they are published, which is what makes it
            safe to build them anywhere.

            Started early so the render overlaps the rest of the interface build. If the render
            has not finished by the time an overlay is asked for, Set-WinUtilTaskbaritem falls
            back to rendering it in place, so nothing waits on this.

            The runspace needs STA because RenderTargetBitmap does; the shared worker pool is
            not, which is why this does not use it.
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

    # One STA runspace for the lifetime of the app: disposing it from the cleanup callback would
    # mean reshaping the compiled helper type, which is only created once per session.
    Register-WinUtilRunspaceCleanup -PowerShell $shell -Handle $handle

    return $handle
}
