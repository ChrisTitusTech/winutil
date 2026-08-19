"""Write WinUtil window and UI Automation diagnostics to an explicit path.

The regular tree does not contain WPF popup-menu entries until the popup is
open. This inspector therefore records the desktop and main window first, then
clicks ``ThemeButton`` and records both the refreshed window tree and any
same-process popup windows. It must run at the same integrity level as WinUtil.
"""

from __future__ import annotations

import argparse
import contextlib
import time
from pathlib import Path

from pywinauto import Desktop
from pywinauto.application import Application

from capture_winutil import find_winutil_hwnd


def dump_tree(element, depth: int = 0, max_depth: int = 6) -> None:
    """Print a bounded UI Automation subtree without failing on stale elements."""
    if depth > max_depth:
        return

    indent = "  " * depth
    try:
        control_type = element.element_info.control_type
        name = element.element_info.name or ""
        automation_id = element.element_info.automation_id or ""
        class_name = element.element_info.class_name or ""
        print(
            f"{indent}[{control_type}] name={name!r:40s} "
            f"auto_id={automation_id!r:30s} class={class_name!r}"
        )
    except Exception as exc:
        print(f"{indent}<element inspection failed: {exc}>")
        return

    try:
        children = element.children()
    except Exception as exc:
        print(f"{indent}<child enumeration failed: {exc}>")
        return
    for child in children:
        dump_tree(child, depth + 1, max_depth)


def inspect_winutil() -> None:
    """Print desktop, WinUtil, and transient theme-menu diagnostics."""
    print("=== All visible top-level windows (win32 backend) ===")
    for window in Desktop(backend="win32").windows():
        try:
            if window.is_visible():
                print(
                    f"  title={window.window_text()!r:50s} "
                    f"class={window.class_name()!r}"
                )
        except Exception as exc:
            print(f"  <window inspection failed: {exc}>")

    print("\n=== Looking for WinUtil (shared strict lookup) ===")
    winutil_hwnd, _, _ = find_winutil_hwnd()

    print("\n=== Control tree via UIA backend ===")
    try:
        app = Application(backend="uia").connect(handle=winutil_hwnd)
        window = app.window(handle=winutil_hwnd)
        dump_tree(window)

        print("\n=== Opening theme popup and dumping its UIA tree ===")
        theme_button = window.child_window(
            auto_id="ThemeButton",
            control_type="Button",
        ).wrapper_object()
        window.set_focus()
        theme_button.click_input()
        time.sleep(0.5)

        print("\n=== Main WinUtil UIA tree with theme popup open ===")
        dump_tree(window)

        # WPF may expose the menu as a separate top-level popup or attach it to
        # the main tree depending on framework and rendering state. Record both.
        popup_windows = [
            candidate
            for candidate in app.windows(visible_only=True)
            if candidate.handle != winutil_hwnd
        ]
        if not popup_windows:
            print("No separate same-process popup window was found.")
        for popup in popup_windows:
            print(
                f"Popup HWND={hex(popup.handle)} "
                f"title={popup.window_text()!r} class={popup.class_name()!r}"
            )
            dump_tree(popup)
    except Exception as exc:
        raise RuntimeError(
            "UI Automation inspection failed. Run at the same elevation level "
            "as WinUtil."
        ) from exc


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Write WinUtil UI Automation diagnostics."
    )
    parser.add_argument("output", type=Path, help="Destination text file")
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    failure = None
    # Preserve diagnostics even when discovery or UIA access fails, then return a
    # non-zero exit so local callers and CI do not mistake the dump for success.
    with args.output.open("w", encoding="utf-8") as output_file:
        with contextlib.redirect_stdout(output_file):
            try:
                inspect_winutil()
            except Exception as exc:
                print(f"\nInspection failed: {exc}")
                if exc.__cause__:
                    print(f"Cause: {exc.__cause__}")
                failure = exc

    print(f"Diagnostics written to {args.output}")
    if failure:
        raise failure


if __name__ == "__main__":
    main()
