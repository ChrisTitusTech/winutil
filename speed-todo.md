# Speed TODO

WinUtil currently does too much work before the first GUI paint. Work from the top down: measure first, improve perceived launch time next, then clean up deeper execution/runspace paths.

## P0 - Measure First

- [x] Add temporary startup timing checkpoints with `System.Diagnostics.Stopwatch`.
- [x] Measure config embedding/load, runspace pool initialization, XAML load, theme application, install UI creation, tweaks UI creation, feature UI creation, AppX UI creation, and asset rendering.
- [x] Record baseline launch timing on a clean run and a warm run.
- [x] Keep timing output in the existing WinUtil log/transcript path.
- [x] Remove or gate temporary timing noise after the optimization work is validated.

## P1 - Faster First Paint

- [x] Show the main window before building every non-visible panel.
- [x] Build only the default visible tab during startup.
- [x] Move Tweaks, Features, AppX, and Win11 ISO tab initialization to first tab activation.
- [x] Add one-time guards so each lazy tab initializes only once.
- [x] Preserve current behavior for `-Preset` and `-Config` automation paths.

## P2 - Install Tab Rendering

- [ ] Reduce up-front creation of all install app entries.
- [ ] Keep category/app grouping as pure data before touching WPF controls.
- [ ] Create WPF controls only on the UI thread.
- [ ] Investigate replacing eager app-entry creation with item templates or incremental category rendering.
- [ ] Verify search, selected-app counts, right-click popup, install, uninstall, and import/export selection state still work.

## P3 - Toggle And Registry Startup Cost

- [ ] Stop doing expensive registry-backed toggle status checks while constructing invisible UI.
- [ ] Defer toggle state reads until the Tweaks tab is first opened.
- [ ] Review `Get-WinUtilToggleStatus` so a status read does not create missing registry paths unless that behavior is explicitly required.
- [ ] Batch or cache repeated registry checks where possible.
- [ ] Verify toggle import, undo, preset, and manual click behavior still match current expectations.

## P4 - Runspace Cleanup

- [ ] Refactor `Invoke-WPFRunspace` to avoid shared `$script:powershell` and `$script:handle` state for concurrent callers.
- [ ] Keep the shared runspace pool alive for the app lifetime instead of disposing it from individual queued calls.
- [ ] Add explicit completion cleanup for each PowerShell instance after `EndInvoke`.
- [ ] Add focused Pester coverage for multiple queued runspace calls, failures, and cleanup.
- [ ] Do not parallelize winget/choco package installs by default; package manager locking and prompts make that unsafe.

## P5 - Defer Runspace Pool Startup

- [ ] Move GUI runspace pool creation after first render when no automation mode is active.
- [ ] Keep synchronous runspace pool creation for `-Preset` and `-Config`.
- [ ] Prewarm the pool shortly after `ContentRendered` so later actions do not feel delayed.
- [ ] Ensure closing the form disposes the pool if it was created.
- [ ] Verify buttons that queue work create or reuse the pool safely.

## P6 - Asset And Theme Cost

- [ ] Measure `Invoke-WinUtilAssets -Render` calls during startup.
- [ ] Cache rendered logo, checkmark, and warning images once per process.
- [ ] Defer non-critical taskbar overlay assets until after first render if measurable.
- [ ] Verify taskbar overlay success/error states still display correctly.

## P7 - Verification

- [ ] Run `.\Compile.ps1`.
- [ ] Run focused Pester tests for runspace, config, XAML wiring, install workflow, tweaks, and preferences/theme.
- [ ] Run the full Pester gate before marking speed work complete.
- [ ] Manually launch with `.\Compile.ps1 -Run` and verify first paint, default tab, lazy tabs, search, install selection, tweak toggles, AppX tab, and Win11 ISO tab.
- [ ] Check `git status --short` and do not stage or commit generated `winutil.ps1`.
