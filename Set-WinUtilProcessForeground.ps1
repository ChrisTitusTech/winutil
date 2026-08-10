function Set-WinUtilProcessForeground {
    <#
    .SYNOPSIS
        Brings a just-started process's main window to the foreground.

    .DESCRIPTION
        Interactive installers launched from WinUtil's background install runspace don't
        reliably get Windows' automatic foreground grant - that's tied to whichever thread
        most recently received user input (the UI thread that handled the button click), not
        the background thread that actually calls Start-Process. Polls briefly for the new
        process's main window to appear, then explicitly foregrounds it. Uses the well-known
        ALT-keypress workaround for SetForegroundWindow's foreground-lock restriction (a
        simulated key event satisfies the "was this the last input" check Windows applies).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Process]$Process,

        [int]$TimeoutSeconds = 15
    )

    if (-not ([System.Management.Automation.PSTypeName]'WinUtil.ForegroundWindowNative').Type) {
        Add-Type -Namespace WinUtil -Name ForegroundWindowNative -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
[DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
[DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
'@ -ErrorAction Stop
    }

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $Process.Refresh()
        if ($Process.HasExited) { return }
        if ($Process.MainWindowHandle -ne [IntPtr]::Zero) { break }
        Start-Sleep -Milliseconds 200
    }

    if ($Process.MainWindowHandle -eq [IntPtr]::Zero) { return }

    if ([WinUtil.ForegroundWindowNative]::IsIconic($Process.MainWindowHandle)) {
        [void][WinUtil.ForegroundWindowNative]::ShowWindow($Process.MainWindowHandle, 9)  # SW_RESTORE
    }

    [WinUtil.ForegroundWindowNative]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero)   # VK_MENU (Alt) down
    [void][WinUtil.ForegroundWindowNative]::SetForegroundWindow($Process.MainWindowHandle)
    [WinUtil.ForegroundWindowNative]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)   # Alt up (KEYEVENTF_KEYUP)
}
