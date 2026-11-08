function Invoke-WinUtilExplorerUpdate {
     <#
    .SYNOPSIS
        Refreshes the Windows Explorer
    #>
    param (
        [string]$action = "refresh"
    )

    if ($action -eq "refresh") {
        # The handle is of no use to the caller, and leaving it in the pipeline puts it into
        # whatever result the calling workflow returns
        $null = Invoke-WPFRunspace -ScriptBlock {
            # Define the Win32 type only if it doesn't exist
            if (-not ([System.Management.Automation.PSTypeName]'Win32').Type) {
                Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = false)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd, uint Msg, IntPtr wParam, string lParam,
        uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
}
"@
            }

            $HWND_BROADCAST = [IntPtr]0xffff
            $WM_SETTINGCHANGE = 0x1A
            $SMTO_ABORTIFHUNG = 0x2

            [Win32]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE,
                [IntPtr]::Zero, "ImmersiveColorSet", $SMTO_ABORTIFHUNG, 100,
                [ref]([IntPtr]::Zero))
        }
    } elseif ($action -eq "restart") {
        # Kill only this session's Explorer so per-user tweaks cannot tear down other
        # logged-on users' shells (shared availability).
        $currentSessionId = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
        Get-Process -Name explorer -ErrorAction SilentlyContinue |
            Where-Object { $_.SessionId -eq $currentSessionId } |
            ForEach-Object { taskkill.exe /F /PID $_.Id | Out-Null }
        Start-Process "explorer.exe"
    }
}
