"""Generate WinUtil's Light and Dark Tweaks title-screen composite.

The automation targets a strictly validated WinUtil WPF window, selects the
Tweaks tab, and chooses the explicit Dark and Light menu items rather than
toggling an unknown initial state. Raw captures live in a temporary directory;
only the requested composite output persists.

Local execution must use the same elevation level as WinUtil. CI may provide
``WINUTIL_HWND`` to bypass desktop discovery after launching a known window.
The current maximized WPF bounds determine the capture dimensions.
"""

from __future__ import annotations

import argparse
import tempfile
import time
from pathlib import Path

from PIL import Image, ImageStat
from pywinauto.application import Application

from capture_winutil import (
    capture_window,
    find_winutil_hwnd,
    get_window_capture_size,
)
from create_composite import create_composite


CONTROL_TIMEOUT_SECONDS = 10
MENU_SETTLE_SECONDS = 0.25
TAB_SETTLE_SECONDS = 1.0
THEME_SETTLE_SECONDS = 2.0
WINDOW_SETTLE_SECONDS = 0.5
THEME_BRIGHTNESS_THRESHOLD = 128
SUPPORTED_THEMES = {"Dark", "Light"}


def is_dark_mode(image: Image.Image) -> bool:
    """Return whether the stable center band resembles WinUtil's Dark theme.

    The center band avoids the title-bar icons and outer DWM frame. Current Dark
    captures average roughly 30-40 luminance while Light captures are above 230,
    leaving a wide margin around the midpoint threshold.
    """
    width, height = image.size
    sample = image.crop(
        (
            width // 4,
            height // 2 - 10,
            3 * width // 4,
            height // 2 + 10,
        )
    ).convert("L")
    return ImageStat.Stat(sample).mean[0] < THEME_BRIGHTNESS_THRESHOLD


def capture_theme(
    hwnd,
    width: int,
    height: int,
    output_path: str | Path,
    *,
    expected_dark: bool,
) -> Image.Image:
    """Capture a theme and reject a stale or unsuccessful theme change."""
    image = capture_window(hwnd, width, height, output_path)
    actual_dark = is_dark_mode(image)
    if actual_dark != expected_dark:
        expected_name = "Dark" if expected_dark else "Light"
        actual_name = "Dark" if actual_dark else "Light"
        raise RuntimeError(
            f"Expected {expected_name} mode after selecting its theme menu item, "
            f"but the capture looks {actual_name}."
        )
    return image


def maximize_window(hwnd) -> tuple[int, int]:
    """Maximize WinUtil and return its refreshed physical capture dimensions."""
    app = Application(backend="win32").connect(
        handle=hwnd,
        timeout=CONTROL_TIMEOUT_SECONDS,
    )
    window = app.window(handle=hwnd).wrapper_object()
    window.maximize()
    time.sleep(WINDOW_SETTLE_SECONDS)
    return get_window_capture_size(hwnd)


def select_tweaks_tab(hwnd) -> None:
    """Select the Tweaks tab through its stable WPF automation identifier."""
    app = Application(backend="uia").connect(
        handle=hwnd,
        timeout=CONTROL_TIMEOUT_SECONDS,
    )
    window = app.window(handle=hwnd)
    tweaks_spec = window.child_window(
        auto_id="WPFTab2BT",
        control_type="Button",
    )
    try:
        tweaks_spec.wait(
            "exists enabled visible ready",
            timeout=CONTROL_TIMEOUT_SECONDS,
        )
        tweaks_button = tweaks_spec.wrapper_object()
    except Exception as exc:
        raise RuntimeError(
            f"Tweaks button WPFTab2BT was not available in HWND {hex(hwnd)}. "
            "Confirm WinUtil is fully loaded and run at the same elevation level."
        ) from exc

    window.set_focus()
    tweaks_button.click_input()
    time.sleep(TAB_SETTLE_SECONDS)


def set_theme(hwnd, theme_name: str) -> None:
    """Open WinUtil's theme menu and choose an explicit theme menu item."""
    if theme_name not in SUPPORTED_THEMES:
        supported = ", ".join(sorted(SUPPORTED_THEMES))
        raise ValueError(
            f"Unsupported WinUtil theme {theme_name!r}; expected one of {supported}."
        )

    # WPF can replace automation elements while swapping its resource dictionary,
    # so each theme selection starts with a fresh UIA connection and wrapper.
    app = Application(backend="uia").connect(
        handle=hwnd,
        timeout=CONTROL_TIMEOUT_SECONDS,
    )
    window = app.window(handle=hwnd)
    theme_button_spec = window.child_window(
        auto_id="ThemeButton",
        control_type="Button",
    )
    try:
        theme_button_spec.wait(
            "exists enabled visible ready",
            timeout=CONTROL_TIMEOUT_SECONDS,
        )
        theme_button = theme_button_spec.wrapper_object()
    except Exception as exc:
        raise RuntimeError(
            f"ThemeButton was not available in HWND {hex(hwnd)}. Confirm WinUtil "
            "is fully loaded and run at the same elevation level."
        ) from exc

    # ThemeButton advertises UIA InvokePattern, but its WinUtil handler requires
    # real pointer input. click_input sends the same mouse path as a user click.
    window.set_focus()
    theme_button.click_input()
    time.sleep(MENU_SETTLE_SECONDS)

    deadline = time.monotonic() + CONTROL_TIMEOUT_SECONDS
    popup_details = []
    while time.monotonic() < deadline:
        popup_windows = [
            candidate
            for candidate in app.windows(visible_only=True)
            if candidate.handle != hwnd
        ]
        popup_details = [
            f"{popup.window_text()!r} ({popup.class_name()})"
            for popup in popup_windows
        ]

        # Framework versions differ on whether a WPF menu is attached to the main
        # UIA tree or exposed as its own top-level popup, so search both forms.
        search_roots = [*popup_windows, window.wrapper_object()]
        for root in search_roots:
            matching_controls = root.descendants(title=theme_name)
            if matching_controls:
                matching_controls[0].click_input()
                time.sleep(THEME_SETTLE_SECONDS)
                return
        time.sleep(0.1)

    visible_popups = ", ".join(popup_details) if popup_details else "none"
    raise RuntimeError(
        f"Theme popup opened, but its {theme_name!r} option was not found in the "
        "refreshed WinUtil UIA tree. Run inspect_winutil.py to check whether the "
        f"menu changed. Visible same-process popups: {visible_popups}."
    )


def generate_title_screen(output_path: str | Path) -> Path:
    """Capture both themes and write one final title-screen composite."""
    output_path = Path(output_path)

    print("Locating WinUtil window...")
    hwnd, _, _ = find_winutil_hwnd()

    print("Maximizing WinUtil...")
    width, height = maximize_window(hwnd)

    print("Selecting Tweaks tab...")
    select_tweaks_tab(hwnd)

    print("Selecting Dark theme...")
    set_theme(hwnd, "Dark")

    with tempfile.TemporaryDirectory(prefix="winutil-title-screen-") as temp_dir:
        capture_directory = Path(temp_dir)
        dark_path = capture_directory / "winutil-dark.png"
        light_path = capture_directory / "winutil-light.png"

        print("Capturing Dark theme...")
        capture_theme(
            hwnd,
            width,
            height,
            dark_path,
            expected_dark=True,
        )

        print("Selecting Light theme...")
        set_theme(hwnd, "Light")

        print("Capturing Light theme...")
        capture_theme(
            hwnd,
            width,
            height,
            light_path,
            expected_dark=False,
        )

        print("Generating title-screen composite...")
        create_composite(dark_path, light_path, output_path)

    print(f"Generated title screen: {output_path}")
    return output_path


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Capture WinUtil's Light and Dark Tweaks title screen."
    )
    parser.add_argument("--output", required=True, type=Path, help="Destination PNG")
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    generate_title_screen(args.output)


if __name__ == "__main__":
    main()
