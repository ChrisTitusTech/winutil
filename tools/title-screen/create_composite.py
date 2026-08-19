"""Create WinUtil's framed diagonal Light and Dark title-screen image.

WinUtil captures include a narrow near-black DWM shadow around the actual WPF
window. The compositor detects that shadow from the Dark capture, applies the
same crop to both themes, and blends them with a supersampled diagonal mask.
Only the final composite is written; the cropped and framed theme images remain
in memory.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


BORDER_COLOR = (180, 180, 180, 255)
BORDER_WIDTH = 2
# DWM shadow pixels are nearly black. WinUtil's actual Dark theme remains above
# this threshold at the window edges used by the bounds scan.
BRIGHTNESS_THRESHOLD = 20
LARGE_SHADOW_MARGIN = 30
MASK_SCALE = 4
# These endpoints keep the split clear of the left tab labels near the top and
# the right-side action controls near the bottom of the Tweaks layout.
TOP_SPLIT = 0.16
BOTTOM_SPLIT = 0.86


def _contains_content(pixel) -> bool:
    """Return whether a pixel is brighter than the near-black DWM shadow."""
    return any(channel > BRIGHTNESS_THRESHOLD for channel in pixel[:3])


def _find_content_bounds(image: Image.Image) -> tuple[int, int, int, int]:
    """Return the non-shadow bounds detected from a Dark theme capture.

    Every edge coordinate is checked because Windows 11 shadows can be narrower
    than ten pixels. Sampling at a fixed interval could skip the first content
    pixel and trim real UI from the final image.
    """
    width, height = image.size
    pixels = image.load()

    left = next(
        (
            x
            for x in range(width)
            if any(_contains_content(pixels[x, y]) for y in range(height))
        ),
        0,
    )
    right = next(
        (
            x
            for x in range(width - 1, -1, -1)
            if any(_contains_content(pixels[x, y]) for y in range(height))
        ),
        width - 1,
    )
    top = next(
        (
            y
            for y in range(height)
            if any(_contains_content(pixels[x, y]) for x in range(width))
        ),
        0,
    )
    bottom = next(
        (
            y
            for y in range(height - 1, -1, -1)
            if any(_contains_content(pixels[x, y]) for x in range(width))
        ),
        height - 1,
    )

    right_margin = width - right - 1
    bottom_margin = height - bottom - 1
    margins = (left, top, right_margin, bottom_margin)
    if any(margin > LARGE_SHADOW_MARGIN for margin in margins):
        print(
            "Warning: unusually large shadow margins detected "
            f"(left={left}, top={top}, right={right_margin}, "
            f"bottom={bottom_margin}). Input images may already be cropped or "
            "framed."
        )

    return left, top, right + 1, bottom + 1


def _apply_frame(image: Image.Image) -> Image.Image:
    """Return a copy with the title-screen border drawn inside its bounds."""
    framed = image.copy()
    width, height = framed.size
    draw = ImageDraw.Draw(framed)
    for inset in range(BORDER_WIDTH):
        draw.rectangle(
            [inset, inset, width - 1 - inset, height - 1 - inset],
            outline=BORDER_COLOR,
        )
    return framed


def create_composite(
    dark_path: str | Path,
    light_path: str | Path,
    output_path: str | Path,
) -> Path:
    """Create one framed diagonal composite from matching theme captures."""
    dark_path = Path(dark_path)
    light_path = Path(light_path)
    output_path = Path(output_path)

    with Image.open(dark_path) as dark_source:
        dark_image = dark_source.convert("RGBA")
    with Image.open(light_path) as light_source:
        light_image = light_source.convert("RGBA")

    if dark_image.size != light_image.size:
        raise ValueError(
            "Image dimensions do not match: "
            f"Dark is {dark_image.size}, Light is {light_image.size}"
        )

    crop_box = _find_content_bounds(dark_image)
    print(f"Content crop box (stripping DWM shadow): {crop_box}")

    dark_framed = _apply_frame(dark_image.crop(crop_box))
    light_framed = _apply_frame(light_image.crop(crop_box))
    width, height = dark_framed.size

    # Drawing the mask at four times the target resolution and downsampling it
    # with Lanczos produces a smooth diagonal without softening either UI image.
    mask_width = width * MASK_SCALE
    mask_height = height * MASK_SCALE
    mask_high_resolution = Image.new("L", (mask_width, mask_height), 0)
    draw_mask = ImageDraw.Draw(mask_high_resolution)
    draw_mask.polygon(
        [
            (0, 0),
            (TOP_SPLIT * mask_width, 0),
            (BOTTOM_SPLIT * mask_width, mask_height),
            (0, mask_height),
        ],
        fill=255,
    )
    mask = mask_high_resolution.resize(
        (width, height),
        resample=Image.Resampling.LANCZOS,
    )

    # A white mask selects Light, so Light occupies the left side and Dark the
    # right. Reapplying the frame removes any mask antialiasing at the outer edge.
    composite = Image.composite(light_framed, dark_framed, mask)
    composite = _apply_frame(composite)
    composite.save(output_path, "PNG")

    print(f"Generated title-screen composite: {output_path} ({width}x{height})")
    return output_path


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create WinUtil's diagonal Light and Dark title-screen image."
    )
    parser.add_argument("dark", type=Path, help="Raw Dark theme PNG")
    parser.add_argument("light", type=Path, help="Raw Light theme PNG")
    parser.add_argument("output", type=Path, help="Destination composite PNG")
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    create_composite(args.dark, args.light, args.output)


if __name__ == "__main__":
    main()
