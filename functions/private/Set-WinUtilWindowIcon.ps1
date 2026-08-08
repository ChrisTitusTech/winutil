function Set-WinUtilWindowIcon {
    <#
        .SYNOPSIS
            Gives the window its own icon, rasterised at the sizes Windows asks for

        .DESCRIPTION
            Windows uses two icons for a window: a small one for the title bar and the alt-tab
            list, and a large one for the taskbar. It asks for them at sizes that depend on the
            display's scaling, so handing it a single bitmap leaves it to scale, and a logo
            scaled from one size looks different on every machine.

            Both are drawn from the vector at exactly the size the system reports, which is what
            keeps it sharp at any scaling. The WPF Icon property is set too, since that is what
            the window's own chrome and some dialogs use.
    #>

    if ($null -eq $sync.Form) {
        return
    }

    if (-not ("WinUtilWindowIcon" -as [type])) {
        Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class WinUtilWindowIcon
{
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern int GetSystemMetrics(int index);
    [DllImport("user32.dll")] public static extern bool DestroyIcon(IntPtr handle);

    public const int WM_SETICON = 0x0080;
    public const int ICON_SMALL = 0;
    public const int ICON_BIG = 1;
    public const int SM_CXSMICON = 49;
    public const int SM_CXICON = 11;
}
"@
    }

    $handle = (New-Object System.Windows.Interop.WindowInteropHelper $sync.Form).Handle
    if ($handle -eq [IntPtr]::Zero) {
        return
    }

    Add-Type -AssemblyName System.Drawing

    # The metrics already account for the display scaling, so this is the real pixel size
    $smallSize = [WinUtilWindowIcon]::GetSystemMetrics([WinUtilWindowIcon]::SM_CXSMICON)
    $largeSize = [WinUtilWindowIcon]::GetSystemMetrics([WinUtilWindowIcon]::SM_CXICON)
    if ($smallSize -le 0) { $smallSize = 16 }
    if ($largeSize -le 0) { $largeSize = 32 }

    $previous = @($sync.WindowIconHandles)
    $handles = New-Object System.Collections.Generic.List[System.IntPtr]

    foreach ($icon in @(
            @{ Size = $smallSize; Which = [WinUtilWindowIcon]::ICON_SMALL },
            @{ Size = $largeSize; Which = [WinUtilWindowIcon]::ICON_BIG })) {

        try {
            $bitmapSource = Invoke-WinUtilAssets -Type "logo" -Size $icon.Size -Render
            $iconHandle = ConvertTo-WinUtilIconHandle -Source $bitmapSource
            if ($iconHandle -eq [IntPtr]::Zero) { continue }

            $null = [WinUtilWindowIcon]::SendMessage($handle, [WinUtilWindowIcon]::WM_SETICON, [IntPtr]$icon.Which, $iconHandle)
            $handles.Add($iconHandle)
        } catch {
            Write-WinUtilLog -Level "WARN" -Component "UI" -Message "Could not set the $($icon.Size)px window icon: $($_.Exception.Message)"
        }
    }

    # Held for the life of the window: the icon stays in use after the message returns
    $sync.WindowIconHandles = $handles

    # Freed only once the replacements are in place
    foreach ($old in $previous) {
        if ($old -and $old -ne [IntPtr]::Zero) { $null = [WinUtilWindowIcon]::DestroyIcon($old) }
    }

    try {
        $sync.Form.Icon = Invoke-WinUtilAssets -Type "logo" -Size 64 -Render
    } catch {
        Write-WinUtilLog -Level "WARN" -Component "UI" -Message "Could not set the window's WPF icon: $($_.Exception.Message)"
    }
}

function ConvertTo-WinUtilIconHandle {
    <#
        .SYNOPSIS
            Turns a rendered bitmap into an icon handle Windows can be given
    #>
    param(
        [Parameter(Mandatory)]
        $Source
    )

    $stream = New-Object System.IO.MemoryStream
    try {
        $encoder = New-Object Windows.Media.Imaging.PngBitmapEncoder
        $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($Source))
        $encoder.Save($stream)
        $stream.Position = 0

        $bitmap = [System.Drawing.Bitmap]::FromStream($stream)
        try {
            return $bitmap.GetHicon()
        } finally {
            $bitmap.Dispose()
        }
    } finally {
        $stream.Dispose()
    }
}
