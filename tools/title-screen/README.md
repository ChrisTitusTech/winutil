# WinUtil title screen

This tool generates the Light and Dark composite used as WinUtil's title screen
in the repository README and documentation site. It opens the Tweaks tab,
captures both themes, and combines them into one PNG. The two raw captures are
temporary and are removed when the command finishes.

## Requirements

- Windows with an interactive desktop
- [uv](https://docs.astral.sh/uv/)
- WinUtil compiled and running
- An elevated PowerShell terminal

Run the commands below from `tools/title-screen`.

## Generate and review a test image

Start WinUtil from the repository root:

```powershell
.\Compile.ps1 -Run
```

With WinUtil still open, return to this directory in an elevated terminal and
generate a test image:

```powershell
uv run --locked python automate_title_screen.py --output "$env:TEMP\winutil-title-screen.png"
```

Open the resulting PNG and check that:

- the Tweaks tab is shown,
- the Light theme is on the upper-left side of the diagonal,
- the Dark theme is on the lower-right side, and
- no desktop background or other windows are visible.

The automation works whether WinUtil starts in Light or Dark mode. It leaves the
window on the Tweaks tab in Light mode.

## Automation

The title screen is updated through a manually triggered GitHub Actions workflow.
When the generated image changes, the workflow opens or updates a pull request
for review. It does not merge the pull request automatically.

Failed runs upload the capture log, UI Automation inspection, and available image
as diagnostic artifacts for 14 days.

## Tests

The tests cover theme detection and composite image generation without opening
WinUtil:

```powershell
uv run --locked python -m unittest discover
```

## Troubleshooting

If WinUtil cannot be found, make sure the compiled WPF window is open and that
the terminal is elevated. The script deliberately ignores editors, terminals,
and browser windows that merely contain "WinUtil" in their title.

If a tab or theme control cannot be found, capture the UI Automation tree while
WinUtil is open:

```powershell
uv run --locked python inspect_winutil.py "$env:TEMP\winutil-inspect.txt"
```

The inspector opens the theme menu before recording its controls. Attach the
text file when reporting a failure. It contains window and control metadata, not
the generated screenshots.
