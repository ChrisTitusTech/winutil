"""Smoke tests for the WinUtil title-screen compositor."""

import tempfile
import unittest
from pathlib import Path

from PIL import Image, ImageDraw

from create_composite import BORDER_COLOR, create_composite


class CreateCompositeTests(unittest.TestCase):
    def test_creates_only_requested_composite(self):
        with tempfile.TemporaryDirectory(prefix="winutil-composite-test-") as temp_dir:
            work_dir = Path(temp_dir)
            dark_path = work_dir / "dark.png"
            light_path = work_dir / "light.png"
            output_path = work_dir / "title-screen.png"

            self._create_capture(dark_path, (32, 34, 36, 255))
            self._create_capture(light_path, (235, 237, 239, 255))

            result = create_composite(dark_path, light_path, output_path)

            self.assertEqual(result, output_path)
            self.assertEqual(
                {path.name for path in work_dir.glob("*.png")},
                {"dark.png", "light.png", "title-screen.png"},
            )
            with Image.open(output_path) as composite:
                self.assertEqual(composite.size, (64, 40))
                self.assertEqual(composite.getpixel((0, 0)), BORDER_COLOR)
                self.assertEqual(composite.getpixel((5, 20)), (235, 237, 239, 255))
                self.assertEqual(composite.getpixel((58, 20)), (32, 34, 36, 255))

    @staticmethod
    def _create_capture(path: Path, content_color: tuple[int, int, int, int]):
        image = Image.new("RGBA", (70, 46), (0, 0, 0, 255))
        draw = ImageDraw.Draw(image)
        draw.rectangle((3, 3, 66, 42), fill=content_color)
        image.save(path, "PNG")


if __name__ == "__main__":
    unittest.main()
