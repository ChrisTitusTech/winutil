# Test TODO

Current suite status: broad parser, import, config JSON, compile, and runspace smoke coverage exists, but runtime behavior coverage is still very thin. Work from the top down; the first items are the highest-value gaps.

## P0 - Highest Priority

- [x] Add config reference integrity tests.
  - Verify every preset entry points to an existing tweak, feature, app, appx item, or supported action.
  - Verify `appnavigation.json` entries point to real tabs/panels and valid config groups.
  - Verify tweak, feature, DNS, appx, and theme entries include all fields used by the UI/rendering code.
  - Verify all embedded script strings in `config/*.json` parse as PowerShell when wrapped as scriptblocks.

- [x] Add XAML/control wiring tests.
  - Load `xaml/inputXML.xaml` as XML and verify expected named controls exist.
  - Verify controls referenced through `$sync["Name"]`, `$sync.Name`, or event handlers exist in XAML or are intentionally created dynamically.
  - Verify `Invoke-WPF*` handler names used by buttons/tabs correspond to real functions.
  - Verify core tabs, search controls, install panels, tweak panels, and Win11 Creator controls are present.

- [x] Add mock-based tests for registry and service helpers.
  - Cover `Set-WinUtilRegistry` set/remove paths with `Mock New-Item`, `Mock Set-ItemProperty`, and `Mock Remove-ItemProperty`.
  - Cover `Set-WinUtilService` for missing services, startup type changes, and no-op behavior.
  - Assert command parameters instead of touching the real registry or services.

- [x] Add package selection and package manager tests.
  - Cover `Get-WinUtilSelectedPackages` for winget-only, choco-only, mixed, `na`, empty, duplicate, and missing package entries.
  - Cover `Test-WinUtilPackageManager` with mocked `Get-Command`.
  - Cover `Install-WinUtilProgramWinget` and `Install-WinUtilProgramChoco` with mocked `Start-Process`, including install/uninstall arguments.

- [x] Add runspace behavior tests beyond the smoke test.
  - Cover no argument list, one named parameter, multiple named parameters, and scriptblock failures.
  - Assert callers receive a single `IAsyncResult`.
  - Verify failure output/errors can be retrieved by the owning PowerShell instance.
  - Add focused tests for public functions that call `Invoke-WPFRunspace` without executing their destructive inner work.

## P1 - Important Workflow Coverage

- [x] Add tweak execution orchestration tests.
  - Cover `Invoke-WinUtilTweaks` with mocked `Invoke-WinUtilScript`, `Set-WinUtilRegistry`, `Set-WinUtilService`, and `Set-WinUtilDNS`.
  - Verify undo mode uses `OriginalValue` and `OriginalType`.
  - Verify DNS provider and progress counters are passed through correctly.

- [x] Add install/uninstall workflow tests.
  - Cover `Invoke-WPFInstall` and `Invoke-WPFUnInstall` with mocked package sorting and mocked installers.
  - Verify empty selection prompts and exits.
  - Verify process-running guard prevents a second install/uninstall.
  - Verify taskbar/progress cleanup happens on success and error.

- [x] Add update profile tests.
  - Cover `Invoke-WPFUpdatesdisable`, `Invoke-WPFUpdatesdefault`, and `Invoke-WPFUpdatessecurity` with mocks for registry, services, scheduled tasks, and process calls.
  - Assert intended registry paths, values, service startup types, and scheduled task paths.
  - Keep all tests non-mutating.

- [x] Add AppX removal tests.
  - Cover `Remove-WinUtilAPPX` with mocked `Get-AppxPackage` and `Remove-AppxPackage`.
  - Cover `Invoke-WPFAppxRemoval` selection behavior and runspace parameter passing.
  - Verify empty selection is handled without removal calls.

- [ ] Add UI selection/state helper tests.
  - Cover `Update-WinUtilSelections`, `Reset-WPFCheckBoxes`, `Invoke-WPFSelectedCheckboxesUpdate`, and `Invoke-WPFToggleAllCategories`.
  - Use small fake checkbox/control objects instead of WPF windows where possible.
  - Verify selected apps, tweaks, toggles, appx, and features stay in sync with checkbox state.

## P2 - Domain-Specific Coverage

- [ ] Expand Win11 Creator tests.
  - Test edition name to edition ID mapping.
  - Test `ei.cfg` and `PID.txt` generation/removal behavior in a temp directory.
  - Test autounattend conversion preserves required nodes and removes unsupported product key paths.
  - Test driver injection branching with mocked DISM commands.
  - Test ISO export fallback when `oscdimg.exe` is missing and winget install fails.

- [ ] Add preferences/theme tests.
  - Cover `Set-Preferences` loading, saving, old preference cleanup, and defaults.
  - Cover theme resource updates without opening the full GUI.
  - Verify theme config contains required brushes/colors used by the theme code.

- [ ] Add search/filter tests.
  - Cover `Find-AppsByNameOrDescription` and `Find-TweaksByNameOrDescription` with fake UI item trees.
  - Verify empty search restores visibility.
  - Verify category labels and panels hide/show correctly.
  - Verify description and display-name matches both work.

- [ ] Add compile contract tests.
  - Verify compiled config key transformation for `applications.json` adds `WPFInstall` prefixes.
  - Verify source ordering in `winutil.ps1`: start script, functions, configs, XAML, autounattend XML, main script.
  - Verify generated build date placeholder is replaced.
  - Verify generated script does not contain unresolved `#{replaceme}`.

## P3 - Nice To Have

- [ ] Add Script Analyzer as a failing CI gate once existing findings are triaged.
- [ ] Add docs generation/link checks for `docs/content`.
- [ ] Add coverage reporting in CI as informational output.
- [ ] Add a lightweight test helper module for fake `$sync`, fake WPF controls, and common mocks.
- [ ] Add regression tests whenever a production bug is fixed.

## Guardrails

- Tests must not mutate the real registry, services, scheduled tasks, package managers, AppX packages, USB disks, ISOs, or user profile state.
- Prefer Pester mocks and temp directories for system-facing code.
- Keep generated `winutil.ps1` ignored and never commit it.
- Run the full gate before marking test work complete:

```powershell
Invoke-Pester -Path 'pester/*.Tests.ps1' -Output Detailed -CI
```
