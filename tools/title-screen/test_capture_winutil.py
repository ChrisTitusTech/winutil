"""Tests for Win32 capture geometry calculations."""

import unittest
from unittest.mock import patch

import capture_winutil


class CaptureGeometryTests(unittest.TestCase):
    def test_captures_full_window_before_cropping_to_dwm_frame(self):
        def get_window_rect(_hwnd, pointer):
            pointer._obj.left = 100
            pointer._obj.top = 200
            pointer._obj.right = 920
            pointer._obj.bottom = 840
            return True

        def get_frame_rect(_hwnd, _attribute, pointer, _size):
            pointer._obj.left = 108
            pointer._obj.top = 201
            pointer._obj.right = 912
            pointer._obj.bottom = 832
            return 0

        with (
            patch.object(capture_winutil.user32, "GetWindowRect", get_window_rect),
            patch.object(
                capture_winutil.dwmapi,
                "DwmGetWindowAttribute",
                get_frame_rect,
            ),
        ):
            geometry = capture_winutil.get_window_capture_geometry(0x1234)
            size = capture_winutil.get_window_capture_size(0x1234)

        self.assertEqual(geometry, (820, 640, (8, 1, 812, 632)))
        self.assertEqual(size, (804, 631))


class WindowIdentityTests(unittest.TestCase):
    def test_accepts_the_versioned_winutil_wpf_window(self):
        self.assertTrue(
            capture_winutil._is_winutil_window(
                "WinUtil 26.09.02", "HwndWrapper[PowerShell;123;abc]"
            )
        )

    def test_rejects_an_editor_title_containing_winutil(self):
        self.assertFalse(
            capture_winutil._is_winutil_window(
                "winutil - Visual Studio Code", "HwndWrapper[DefaultDomain;;abc]"
            )
        )


if __name__ == "__main__":
    unittest.main()
