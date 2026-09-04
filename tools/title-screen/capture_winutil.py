"""Locate and capture the WinUtil WPF window through Win32 APIs.

The module identifies WinUtil by both its title and WPF ``HwndWrapper`` class so
an editor or terminal containing the word "winutil" cannot be captured by
mistake. It opts into physical-pixel DPI coordinates before reading bounds, then
uses ``PrintWindow`` and a 32-bit GDI bitmap to capture the WPF surface without
including the surrounding desktop.
"""

from __future__ import annotations

import argparse
import ctypes
import os
import re
from ctypes import wintypes
from pathlib import Path

from PIL import Image


GENERIC_ALL = 0x10000000
PW_RENDERFULLCONTENT = 2
DIB_RGB_COLORS = 0
BI_RGB = 0
DWMWA_EXTENDED_FRAME_BOUNDS = 9


# Win32 otherwise virtualizes coordinates for DPI-unaware Python processes. The
# older shcore call supports systems where Per-Monitor V2 is unavailable.
try:
    ctypes.windll.user32.SetProcessDpiAwarenessContext(-4)
except Exception:
    try:
        ctypes.windll.shcore.SetProcessDpiAwareness(2)
    except Exception:
        pass


user32 = ctypes.windll.user32
dwmapi = ctypes.windll.dwmapi
gdi32 = ctypes.windll.gdi32
kernel32 = ctypes.windll.kernel32

# ctypes assumes integer arguments and return values unless signatures are
# declared. Explicit handle types prevent silent 32-bit truncation on 64-bit
# Windows, which can otherwise produce invalid windows or GDI crashes.
user32.OpenInputDesktop.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
user32.OpenInputDesktop.restype = wintypes.HDESK
user32.OpenDesktopW.argtypes = [
    wintypes.LPCWSTR,
    wintypes.DWORD,
    wintypes.BOOL,
    wintypes.DWORD,
]
user32.OpenDesktopW.restype = wintypes.HDESK
user32.CloseDesktop.argtypes = [wintypes.HDESK]
user32.CloseDesktop.restype = wintypes.BOOL

WINDOW_ENUM_CALLBACK = ctypes.WINFUNCTYPE(
    wintypes.BOOL,
    wintypes.HWND,
    wintypes.LPARAM,
)
user32.EnumDesktopWindows.argtypes = [
    wintypes.HDESK,
    WINDOW_ENUM_CALLBACK,
    wintypes.LPARAM,
]
user32.EnumDesktopWindows.restype = wintypes.BOOL
user32.EnumWindows.argtypes = [WINDOW_ENUM_CALLBACK, wintypes.LPARAM]
user32.EnumWindows.restype = wintypes.BOOL
user32.IsWindowVisible.argtypes = [wintypes.HWND]
user32.IsWindowVisible.restype = wintypes.BOOL
user32.GetWindowTextLengthW.argtypes = [wintypes.HWND]
user32.GetWindowTextLengthW.restype = ctypes.c_int
user32.GetWindowTextW.argtypes = [wintypes.HWND, wintypes.LPWSTR, ctypes.c_int]
user32.GetWindowTextW.restype = ctypes.c_int
user32.GetClassNameW.argtypes = [wintypes.HWND, wintypes.LPWSTR, ctypes.c_int]
user32.GetClassNameW.restype = ctypes.c_int


class RECT(ctypes.Structure):
    """Win32 rectangle used by both User32 and DWM bounds APIs."""

    _fields_ = [
        ("left", ctypes.c_long),
        ("top", ctypes.c_long),
        ("right", ctypes.c_long),
        ("bottom", ctypes.c_long),
    ]


dwmapi.DwmGetWindowAttribute.argtypes = [
    wintypes.HWND,
    wintypes.DWORD,
    ctypes.c_void_p,
    wintypes.DWORD,
]
dwmapi.DwmGetWindowAttribute.restype = wintypes.DWORD
user32.GetWindowRect.argtypes = [wintypes.HWND, ctypes.POINTER(RECT)]
user32.GetWindowRect.restype = wintypes.BOOL
user32.GetDpiForWindow.argtypes = [wintypes.HWND]
user32.GetDpiForWindow.restype = wintypes.UINT
user32.GetWindowDC.argtypes = [wintypes.HWND]
user32.GetWindowDC.restype = wintypes.HDC
user32.ReleaseDC.argtypes = [wintypes.HWND, wintypes.HDC]
user32.ReleaseDC.restype = ctypes.c_int
user32.PrintWindow.argtypes = [wintypes.HWND, wintypes.HDC, wintypes.UINT]
user32.PrintWindow.restype = wintypes.BOOL

gdi32.CreateCompatibleDC.argtypes = [wintypes.HDC]
gdi32.CreateCompatibleDC.restype = wintypes.HDC
gdi32.CreateCompatibleBitmap.argtypes = [wintypes.HDC, ctypes.c_int, ctypes.c_int]
gdi32.CreateCompatibleBitmap.restype = wintypes.HBITMAP
gdi32.SelectObject.argtypes = [wintypes.HDC, wintypes.HGDIOBJ]
gdi32.SelectObject.restype = wintypes.HGDIOBJ
gdi32.DeleteDC.argtypes = [wintypes.HDC]
gdi32.DeleteDC.restype = wintypes.BOOL
gdi32.DeleteObject.argtypes = [wintypes.HGDIOBJ]
gdi32.DeleteObject.restype = wintypes.BOOL
kernel32.GetLastError.argtypes = []
kernel32.GetLastError.restype = wintypes.DWORD


class BITMAPINFOHEADER(ctypes.Structure):
    """Header describing the top-down, uncompressed bitmap requested from GDI."""

    _fields_ = [
        ("biSize", wintypes.DWORD),
        ("biWidth", ctypes.c_long),
        ("biHeight", ctypes.c_long),
        ("biPlanes", wintypes.WORD),
        ("biBitCount", wintypes.WORD),
        ("biCompression", wintypes.DWORD),
        ("biSizeImage", wintypes.DWORD),
        ("biXPelsPerMeter", ctypes.c_long),
        ("biYPelsPerMeter", ctypes.c_long),
        ("biClrUsed", wintypes.DWORD),
        ("biClrImportant", wintypes.DWORD),
    ]


class BITMAPINFO(ctypes.Structure):
    """GDI bitmap metadata with correctly aligned unused RGB color entries."""

    _fields_ = [
        ("bmiHeader", BITMAPINFOHEADER),
        ("bmiColors", wintypes.DWORD * 3),
    ]


gdi32.GetDIBits.argtypes = [
    wintypes.HDC,
    wintypes.HBITMAP,
    wintypes.UINT,
    wintypes.UINT,
    ctypes.c_void_p,
    ctypes.POINTER(BITMAPINFO),
    wintypes.UINT,
]
gdi32.GetDIBits.restype = ctypes.c_int


def _window_text(hwnd) -> str:
    """Return the title of a top-level window."""
    length = user32.GetWindowTextLengthW(hwnd)
    buffer = ctypes.create_unicode_buffer(length + 1)
    user32.GetWindowTextW(hwnd, buffer, length + 1)
    return buffer.value


def _window_class(hwnd) -> str:
    """Return the Win32 class name of a top-level window."""
    buffer = ctypes.create_unicode_buffer(256)
    user32.GetClassNameW(hwnd, buffer, len(buffer))
    return buffer.value


def _is_winutil_window(title: str, class_name: str) -> bool:
    """Return whether a title and class identify the WinUtil WPF window."""
    return bool(
        re.fullmatch(r"WinUtil \d{2}\.\d{2}\.\d{2}", title, re.IGNORECASE)
        and "hwndwrapper" in class_name.lower()
    )


def _describe_window(hwnd, title: str, class_name: str, width: int, height: int):
    """Print the window identity, DPI scale, and physical capture size."""
    dpi = user32.GetDpiForWindow(hwnd)
    scale = dpi / 96.0 if dpi > 0 else 1.0
    print(
        f"Located HWND: {hex(hwnd)} | Title: {title!r} | Class: {class_name!r} "
        f"| DPI: {dpi} ({scale:.2f}x) | Capture Size: {width}x{height}"
    )


def find_winutil_hwnd():
    """Return the validated WinUtil HWND and physical capture dimensions.

    ``WINUTIL_HWND`` is an optional CI optimization, not a trust boundary: its
    title and WPF class are validated exactly like a discovered window.
    """
    explicit_hwnd = os.environ.get("WINUTIL_HWND")
    if explicit_hwnd:
        try:
            hwnd = int(explicit_hwnd, 0)
        except ValueError as exc:
            raise RuntimeError(
                f"WINUTIL_HWND is not a valid window handle: {explicit_hwnd!r}"
            ) from exc

        title = _window_text(hwnd)
        class_name = _window_class(hwnd)
        if not _is_winutil_window(title, class_name):
            raise RuntimeError(
                f"WINUTIL_HWND {hex(hwnd)} is not the WinUtil WPF window: "
                f"title={title!r}, class={class_name!r}"
            )

        width, height = get_window_capture_size(hwnd)
        _describe_window(hwnd, title, class_name, width, height)
        return hwnd, width, height

    found_windows = {}

    def collect_window(hwnd, _):
        if not user32.IsWindowVisible(hwnd):
            return True

        rect = RECT()
        if not user32.GetWindowRect(hwnd, ctypes.byref(rect)):
            return True
        width = rect.right - rect.left
        height = rect.bottom - rect.top
        if width < 100 or height < 100:
            return True

        title = _window_text(hwnd)
        class_name = _window_class(hwnd)
        if _is_winutil_window(title, class_name):
            found_windows[hwnd] = (hwnd, title, class_name, width, height)
        return True

    callback = WINDOW_ENUM_CALLBACK(collect_window)
    user32.EnumWindows(callback, 0)

    # Hosted runners can expose the GUI on the Default desktop while the calling
    # process sees another input desktop. Enumerating both finds that window
    # without moving this thread between desktops.
    desktop_handles = [
        user32.OpenInputDesktop(0, False, GENERIC_ALL),
        user32.OpenDesktopW("Default", 0, False, GENERIC_ALL),
    ]
    for desktop_handle in desktop_handles:
        if not desktop_handle:
            continue
        try:
            user32.EnumDesktopWindows(desktop_handle, callback, 0)
        finally:
            user32.CloseDesktop(desktop_handle)

    if not found_windows:
        raise RuntimeError(
            "Could not find a visible WinUtil WPF window. Confirm WinUtil is open "
            "and run this command at the same elevation level."
        )

    windows = sorted(
        found_windows.values(),
        key=lambda candidate: candidate[3] * candidate[4],
        reverse=True,
    )
    if len(windows) > 1:
        print(
            f"Warning: found {len(windows)} WinUtil windows; using the largest "
            "WPF window."
        )

    hwnd, title, class_name, _, _ = windows[0]
    width, height = get_window_capture_size(hwnd)
    _describe_window(hwnd, title, class_name, width, height)
    return hwnd, width, height


def get_window_capture_size(hwnd) -> tuple[int, int]:
    """Return the current physical-pixel capture size for a window.

    DWM extended-frame bounds exclude invisible shadow padding and are preferred
    when available. Because DPI awareness is enabled during import, neither the
    DWM nor User32 result should be scaled again.
    """
    _, _, crop_box = get_window_capture_geometry(hwnd)
    left, top, right, bottom = crop_box
    return right - left, bottom - top


def get_window_capture_geometry(hwnd) -> tuple[int, int, tuple[int, int, int, int]]:
    """Return PrintWindow dimensions and the visible-frame crop rectangle."""
    window_rect = RECT()
    if not user32.GetWindowRect(hwnd, ctypes.byref(window_rect)):
        raise RuntimeError(f"GetWindowRect failed for HWND {hex(hwnd)}")

    window_width = window_rect.right - window_rect.left
    window_height = window_rect.bottom - window_rect.top

    frame_rect = RECT()
    frame_result = dwmapi.DwmGetWindowAttribute(
        hwnd,
        DWMWA_EXTENDED_FRAME_BOUNDS,
        ctypes.byref(frame_rect),
        ctypes.sizeof(frame_rect),
    )
    if window_width <= 0 or window_height <= 0:
        raise RuntimeError(f"Window {hex(hwnd)} has invalid bounds")

    frame_left = frame_rect.left - window_rect.left
    frame_top = frame_rect.top - window_rect.top
    frame_right = frame_rect.right - window_rect.left
    frame_bottom = frame_rect.bottom - window_rect.top
    if (
        frame_result == 0
        and 0 <= frame_left < frame_right <= window_width
        and 0 <= frame_top < frame_bottom <= window_height
    ):
        return window_width, window_height, (
            frame_left,
            frame_top,
            frame_right,
            frame_bottom,
        )

    return window_width, window_height, (0, 0, window_width, window_height)


def capture_window(
    hwnd,
    width: int,
    height: int,
    output_path: str | Path,
) -> Image.Image:
    """Capture an HWND to a validated PNG and return the Pillow image.

    The supplied dimensions must match the window's current physical bounds.
    ``PW_RENDERFULLCONTENT`` is attempted first because WPF may render portions
    outside the visible desktop; ordinary ``PrintWindow`` is retained as a
    compatibility fallback.
    """
    output_path = Path(output_path)
    capture_width, capture_height, crop_box = get_window_capture_geometry(hwnd)
    crop_width = crop_box[2] - crop_box[0]
    crop_height = crop_box[3] - crop_box[1]
    if (width, height) != (crop_width, crop_height):
        raise RuntimeError(
            "Window bounds changed before capture: "
            f"expected {width}x{height}, found {crop_width}x{crop_height}."
        )
    window_dc = user32.GetWindowDC(hwnd)
    if not window_dc:
        raise RuntimeError("GetWindowDC failed. Run at the same elevation as WinUtil.")

    memory_dc = gdi32.CreateCompatibleDC(window_dc)
    if not memory_dc:
        user32.ReleaseDC(hwnd, window_dc)
        raise RuntimeError("CreateCompatibleDC failed")

    bitmap = gdi32.CreateCompatibleBitmap(window_dc, capture_width, capture_height)
    if not bitmap:
        gdi32.DeleteDC(memory_dc)
        user32.ReleaseDC(hwnd, window_dc)
        raise RuntimeError("CreateCompatibleBitmap failed")

    # A compatible memory DC receives the pixels rendered by PrintWindow. The
    # previously selected GDI object must be restored before deleting the bitmap.
    previous_bitmap = gdi32.SelectObject(memory_dc, bitmap)
    bitmap_selected = True
    buffer_size = capture_width * capture_height * 4
    pixel_buffer = ctypes.create_string_buffer(buffer_size)

    try:
        success = user32.PrintWindow(hwnd, memory_dc, PW_RENDERFULLCONTENT)
        if not success:
            extended_error = kernel32.GetLastError()
            print(
                f"PrintWindow(2) failed with error {extended_error}; retrying "
                "without PW_RENDERFULLCONTENT."
            )
            success = user32.PrintWindow(hwnd, memory_dc, 0)
            if not success:
                fallback_error = kernel32.GetLastError()
                raise RuntimeError(
                    "PrintWindow failed in both modes. Run at the same elevation "
                    f"as WinUtil. Errors: extended={extended_error}, "
                    f"fallback={fallback_error}."
                )

        bitmap_info = BITMAPINFO()
        bitmap_info.bmiHeader.biSize = ctypes.sizeof(BITMAPINFOHEADER)
        bitmap_info.bmiHeader.biWidth = capture_width
        # Negative height requests a top-down DIB. Positive-height DIBs are stored
        # bottom-up and would produce a vertically flipped PNG.
        bitmap_info.bmiHeader.biHeight = -capture_height
        bitmap_info.bmiHeader.biPlanes = 1
        bitmap_info.bmiHeader.biBitCount = 32
        bitmap_info.bmiHeader.biCompression = BI_RGB

        # GetDIBits requires the source bitmap not to be selected into a DC.
        gdi32.SelectObject(memory_dc, previous_bitmap)
        bitmap_selected = False

        scan_lines = gdi32.GetDIBits(
            memory_dc,
            bitmap,
            0,
            capture_height,
            pixel_buffer,
            ctypes.byref(bitmap_info),
            DIB_RGB_COLORS,
        )
        if scan_lines != capture_height:
            raise RuntimeError(
                f"GetDIBits returned {scan_lines} of {capture_height} expected scan lines."
            )
    finally:
        # GDI handles are process-global and are not reclaimed promptly by Python.
        # Always release them, including when PrintWindow or GetDIBits fails.
        if bitmap_selected:
            gdi32.SelectObject(memory_dc, previous_bitmap)
        gdi32.DeleteObject(bitmap)
        gdi32.DeleteDC(memory_dc)
        user32.ReleaseDC(hwnd, window_dc)

    # GDI writes BGR color bytes, but BI_RGB does not define the fourth byte as
    # alpha. Decode the channel order, then make the window capture fully opaque.
    image = Image.frombytes(
        "RGBA",
        (capture_width, capture_height),
        pixel_buffer.raw,
        "raw",
        "BGRA",
    )
    image.putalpha(255)
    if crop_box != (0, 0, capture_width, capture_height):
        image = image.crop(crop_box)
    # PrintWindow can report success while returning a blank surface across an
    # integrity-level boundary, so reject all-black and all-white captures.
    extrema = image.getextrema()
    if all(channel[1] == 0 for channel in extrema[:3]):
        raise ValueError("Captured image is completely black")
    if all(channel[0] == 255 for channel in extrema[:3]):
        raise ValueError("Captured image is completely white")

    image.save(output_path, "PNG")
    print(f"Verified and saved: {output_path} ({width}x{height})")
    return image


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Capture the visible WinUtil window.")
    parser.add_argument("output", type=Path, help="Destination PNG path")
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    hwnd, width, height = find_winutil_hwnd()
    capture_window(hwnd, width, height, args.output)


if __name__ == "__main__":
    main()
