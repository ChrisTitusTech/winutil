"""Non-GUI tests for title-screen automation validation helpers."""

import unittest

from PIL import Image

from automate_title_screen import is_dark_mode


class AutomateTitleScreenTests(unittest.TestCase):
    def test_classifies_dark_and_light_captures(self):
        dark_image = Image.new("RGB", (100, 100), (35, 35, 35))
        light_image = Image.new("RGB", (100, 100), (240, 240, 240))

        self.assertTrue(is_dark_mode(dark_image))
        self.assertFalse(is_dark_mode(light_image))

if __name__ == "__main__":
    unittest.main()
